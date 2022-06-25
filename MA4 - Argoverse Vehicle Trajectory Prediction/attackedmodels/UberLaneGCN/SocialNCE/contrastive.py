import os
import matplotlib.pyplot as plt
from argoverse.utils.mesh_grid import get_mesh_grid_as_point_cloud
import torch
import torch.nn as nn
import numpy as np
from attackedmodels.UberLaneGCN.SocialNCE.model import ProjHead, EventEncoder
from attackedmodels.UberLaneGCN.SocialNCE.sampling import EventSampler


class SocialNCE():
    """
    Social contrastive loss, encourage the extracted motion representation to be aware of socially unacceptable events.
    In this use case: get closer to on road ground truth trajectory (positive samples), get away from offroad areas (negative samples).
    """

    def __init__(self, config):
        """
        Social NCE config settings. You should directly modify your preferences here (see ReadMe).
        @params:
            config: universal dictionary (contains potentially useful information, good to keep reference)
        @return:
            None
        """

        # safeguard config reference
        self.config = config

        #* expert knowledge preferences for contrastive sampling
        self.sampler = EventSampler()
        ## horizon: length of predicted trajectory
        self.horizon = config["pred_size"]
        ## padding: missing data completion strategy (choose one through index)
        self.data_padding = ['zero', 'repeat'][0]  # use samples far from data, or repeat last
        ## positive sampling strategy (choose one from dict)
        self.pos_horizon = 1  # number of samples per datapoint (typically 1)
        self.pos_sampling = {x: x for x in self.sampler.pos_sampling.keys()}['noisy']
        ## negative sampling strategy (choose one from dict)
        self.neg_horizon = 5  # number of samples per datapoint (appreciation from visus)
        self.neg_sampling = {x: x for x in self.sampler.neg_sampling.keys()}['offroad_cloud']

        #* trajectory encoders
        coords_dim, hidden_dim, final_dim = 2, 8, 8  # just a guess of what could be acceptable
        self.prediction_encoder = ProjHead(
            feat_dim=coords_dim, hidden_dim=hidden_dim, head_dim=final_dim
        ).float().cuda()
        self.coords_xyt_encoder = EventEncoder(
            feat_dim=coords_dim, hidden_dim=hidden_dim, head_dim=final_dim
        ).float().cuda()

        #* trajectory filtering options
        ## selection strategy: trajectory long enough, starts on road and deviates offroad
        self.filter_trajs = True
        ## number of plots desired, allow some slack as it may generate a few more, the implementation is not strict
        ## note: only filtered trajectories if filter enabled, all if filter disabled
        self.visualizations = 30

        #* loss criterion
        ## function choice
        self.criterion = nn.CrossEntropyLoss()
        ## contrastive parameter
        self.temperature = 0.2

        return


    def extract_transform_info(self, data, dims):
        """
        Provides information about trajectory transform used in normalization
        @params:
            data: universal dictionary
                - 'city': 'MIA' > Miami or 'PIT' > Pittsburgh indicator for each scene in batch
                - 'ctrs': agent offset coords (centroids) used in normalization
                - 'theta': map rotation angle (yaw deg) used in normalization
            dims: dictionary detailing dimensions of data created for Social NCE
                - 'batch scenes': number of scenes in data batch
                - 'agents': list of number of agents in each scene of data batch

        @return: city and information about transform used for normalization for each agent in batch
                - cities: 'MIA' > Miami or 'PIT' > Pittsburgh indicator
                - centroids: agent offset coords
                - yaw_degs: map rotation angle
        """
        #* assign a scene's city to each agent in scene
        #> cities info: [agents' city name], type: list(:,1)
        ## decoding bytes to string
        cities = [data['city'][i].decode("utf-8") for i in range(dims['batch scenes']) for _ in range(dims['agents'][i])]
        #* reshape agent centroids
        #> centroids info: [agents, coords xy], type: tensor(:,:)
        #//centroids = torch.cat(data['ctrs'])
        centroids = None
        #* assign a scene's yaw_deg to each agent in scene
        #> yaw_degs info: [agents' yaw angle], type: tensor(:,1)
        #//yaw_degs = torch.tensor([data['theta'][i].tolist() for i in range(dims['batch scenes']) for _ in range(dims['agents'][i])])
        yaw_degs = None

        return cities, centroids, yaw_degs


    def preprocess_trajectories(self, data, dims, argo_map, info_trajs, trajs):
        """
        Preprocesses trajectories based on preferences set in init and further detailed in ReadMe.
        Aims to enhance loss impact and reduce computational cost of sampling.
        @params:
            data: universal dictionary
                - 'gt_preds': contains ground truth predictions for trajs, needs some padding to be used in network
            dims: dictionary detailing dimensions of data created for Social NCE
                - 'batch scenes': number of scenes in data batch
                - 'agents': list of number of agents in each scene of data batch
                - 'horizon': length of ground truth predictions
            argo_map: reference to world map
            info_trajs: as detailed in extract_transform_info(...)
            trajs: data generated by input network, tensor(n agents, horizon, coords xy)

        @return: selection of agents trajectories judged relevant for loss computation
            trajs: input trajectories modified according filtering preferences (see ReadMe)
            gt_trajs: ground truth trajectories padded and adapted for network tensor operations (see ReadMe)
        """
        #* add a useful piece of info to dims dict
        # total number of agents
        dims['n_agents'] = sum(dims['agents'])
        # define scene separation indices to split concatenated batch
        dims['split'] = [sum(dims['agents'][:i]) for i in range(dims['batch scenes']+1)]

        #* pad ground truth trajectories to match horizon length according to config setting
        #> gt_trajs info: [agents, horizon, coords xy], type: tensor(:,:,:)
        # define scene separation indices to split concatenated batch
        if self.data_padding == 'repeat':
            ## repeating last trajectory point
            gt_trajs = torch.tensor([
                traj.tolist() + [traj[-1].tolist()] * (self.horizon - len(traj))
                    for batch_scene in data['gt_preds'] for traj in batch_scene
            ]).cuda()
        if self.data_padding == 'zero':
            ## zero padding trajectory
            gt_trajs = torch.tensor([
                traj.tolist() + [[0, 0]] * (self.horizon - len(traj))
                    for batch_scene in data['gt_preds'] for traj in batch_scene
            ]).cuda()

        #* trajectory selection scheme
        cities, *_  = info_trajs
        if self.filter_trajs == True:
            selection = []
            for i in range(dims['n_agents']):
                # ignore noisy data (overwrites above padding) and get ground truth + predicted source & destination
                gt_src = None
                gt_dst = None
                for k in range(dims['horizon']):
                    if gt_trajs[i][k][0] < 20 or gt_trajs[i][k][1] < 20:
                        gt_trajs[i][k] *= 0  # invalid data set to origin (consistent when sampling invalid data)
                    elif gt_src is None:
                        gt_src = gt_trajs[i][k]
                    else:
                        gt_dst = gt_trajs[i][k]

                pred_src = None
                pred_dst = None
                for k in range(dims['horizon']):
                    if trajs[i][k][0] < 20 or trajs[i][k][1] < 20:
                        trajs[i][k] *= 0  # invalid data set to origin (consistent when sampling invalid data)
                    elif pred_src is None:
                        pred_src = trajs[i][k]
                    else:
                        pred_dst = trajs[i][k]

                if gt_src is None or gt_dst is None or pred_src is None or pred_dst is None:
                    continue

                gt_traj_valid_pts = len(gt_trajs[i][gt_trajs[i][:, 0] > 0])
                traj_valid_pts = len(trajs[i][trajs[i][:, 0] > 0])

                # keep only trajs with ground truth of a seemingly valid length (dist < 100 is too short, > 100000 is missing data)
                if not (10e2 < sum((gt_dst - gt_src) ** 2) < 10e5):
                    continue

                # keep only trajs with more than 40% relevant points & ground truth data points on the horizon
                min_valid_pts = 0.4*dims['horizon']
                if not (traj_valid_pts > min_valid_pts and gt_traj_valid_pts > min_valid_pts):
                    continue

                #* this utility shortcut returns True if xy is offroad else False
                def offroad_point(xy):
                    return ~argo_map.get_raster_layer_points_boolean(xy.detach().cpu().numpy()[None, :], cities[i], 'driveable_area')

                # keep only trajectories that start on road
                gt_src_offroad, pred_src_offroad = offroad_point(gt_src), offroad_point(pred_src)
                if gt_src_offroad or pred_src_offroad:
                    continue

                # keep only trajectories that end off road even though ground truth is on road
                gt_dst_offroad, pred_dst_offroad = offroad_point(gt_dst), offroad_point(pred_dst)
                if gt_dst_offroad or not pred_dst_offroad:
                    continue

                selection += [i]
        else:
            selection = list(range(dims['n_agents']))  # similar to slice(None, None, None) but list access desired for uniformity

        #* if some agents were filter out, reconfigure data info for scene separation and efficient sampling
        if len(selection) < dims['n_agents']:
            # apply selection filter
            trajs = trajs[selection]
            gt_trajs = gt_trajs[selection]

            # adapt info_trajs
            cities = np.array(cities)[selection].tolist()
            #//centroids = centroids[selection]
            #//yaw_degs = yaw_degs[selection]

            # redefine batch split indices and number of agents
            j, new_split = 0, [0]
            for i in range(1, len(dims['split'])):
                while j < len(selection) and selection[j] < dims['split'][i]:
                    j += 1
                new_split += [j]

            dims['split'] = new_split
            dims['agents'] = [dims['split'][i] - dims['split'][i-1] for i in range(1, len(dims['split']))]
            dims['n_agents'] = len(selection)

        return trajs, gt_trajs


    def generate_samples(self, info_trajs, trajs, gt_trajs, dims, argo_map):
        """
        Generates positive and negatives event samples using strategies configured at init
        @params:
            info_trajs: as detailed in extract_transform_info(...)
            trajs: predicted trajectories of agents
            gt_trajs: ground truth trajectories of agents
            dims: dictionary detailing dimensions of data created for Social NCE
                - 'horizon': length of trajectory prediction
                - 'xxx/horizon': number of pos/neg samples to generate per horizon
            argo_map: argoverse map

        @return:
            _ : tuple of dict with coords 'xy' and time 't' of event samples (pos/neg)
        """
        #* collecting positive and negative samples
        ## positive and negative sampling strategies configured upstream
        #> sample_pos info: [agents, horizon, pos/horizon, coords xy], type: tensor(:,:,:,:)
        #> sample_neg info: [agents, horizon, neg/horizon, coords xy], type: tensor(:,:,:,:)
        coords_pos = self.sampler.pos_sampling[self.pos_sampling](
            info=info_trajs, trajs=trajs, gt_trajs=gt_trajs, n_samples=dims['pos/horizon'], argo_map=argo_map
        ).float().cuda()
        coords_neg = self.sampler.neg_sampling[self.neg_sampling](
            info=info_trajs, trajs=trajs, gt_trajs=gt_trajs, n_samples=dims['neg/horizon'], argo_map=argo_map
        ).float().cuda()

        #* create timeline for samples
        ## arange provides time vector, repeat it over all contrastive samples, tile it for all agents
        #> time_pos info: [agents, horizon, pos/horizon's time t], type: tensor(:,:,:,1)
        #> time_neg info: [agents, horizon, neg/horizon's time t], type: tensor(:,:,:,1)
        time_pos = torch.from_numpy(
            np.tile(np.arange(dims['horizon']).repeat(dims['pos/horizon']), coords_pos.shape[0])
            .reshape(*coords_pos.shape[:-1], 1)
        ).float().cuda()
        time_neg = torch.from_numpy(
            np.tile(np.arange(dims['horizon']).repeat(dims['neg/horizon']), coords_neg.shape[0])
            .reshape(*coords_neg.shape[:-1], 1)
        ).float().cuda()

        return coords_pos, time_pos, coords_neg, time_neg


    def contrastive_loss(self, data, feat, argo_map):
        """
        Social NCE loss as dictated by config settings at init (see ReadMe)
        @params:
            data: universal dictionary
            feat: trajectory projection head
            argo_map: argoverse map

        @return:
            loss: cross entropy loss measuring similarity between feat and expert knowledge samples
        """
        #* utility code to evaluate data dimensions (custom data respects the pattern below)
        dims = {
            'batch scenes': len(data['gt_preds']),  # ignore, reshaped asap by concatenating agents
            'agents': [len(x) for x in data['gt_preds']],  # add elements
            'horizon': self.horizon,
            'pos/horizon': self.pos_horizon, 'neg/horizon': self.neg_horizon,  # choose one
            'coords xy': 2, 'time t': 1,  # choose one
        }

        #* extract trajectory transform info (used in normalization when sampling)
        info_trajs = self.extract_transform_info(data, dims)
        #* complete data and select relevant trajectories
        trajs, gt_trajs = self.preprocess_trajectories(data, dims, argo_map, info_trajs, feat)
        #* generate positive and negative event samples according to strategy defined at init
        pos_xy, pos_t, neg_xy, neg_t = self.generate_samples(info_trajs, trajs, gt_trajs, dims, argo_map)

        #* if visualization enabled, generate images of the first batch
        if self.visualizations > 0:
            visu_dir = self.config['save_dir'] + '/visus/'
            cities, *_ = info_trajs
            for i in range(dims['batch scenes']):
                scene = slice(dims['split'][i], dims['split'][i+1])
                if len(trajs[scene]) > 0:
                    city = cities[dims['split'][i]]
                    self.visualize_scenario(
                        argo_map=argo_map, scene_id=data['idx'][i], origin=data['orig'][i],
                        city=city, trajs=trajs[scene], pos_samples=pos_xy[scene], neg_samples=neg_xy[scene],
                        save_dir=visu_dir, img_format='png'
                    )
                    self.visualizations -= 1

        #* fuse spacetime keys :P (into ? dimensions specified by encoder)
        #> key_pos info: [agents, horizon, pos/horizon, ?], type: tensor(:,:,:,:)
        #> key_neg info: [agents, horizon, neg/horizon, ?], type: tensor(:,:,:,:)
        key_pos = nn.functional.normalize(
            self.coords_xyt_encoder(state=pos_xy, time=pos_t), dim=-1
        )
        key_neg = nn.functional.normalize(
            self.coords_xyt_encoder(state=neg_xy, time=neg_t), dim=-1
        )

        #* encode nce input trajectory predictions in a similar way
        #> query info: [agents, ?], type: tensor(:,:)
        query = nn.functional.normalize(
            self.prediction_encoder(feat=trajs[:, :, None, :]), dim=-1
        )

        #* compute similarity of embeddings
        #> sim_pos info: [agents * horizon, pos/horizon], type: tensor(:,:)
        #> sim_neg info: [agents * horizon, neg/horizon], type: tensor(:,:)
        sim_pos = torch.sum(query * key_pos, dim=-1)
        sim_pos = sim_pos.view(sim_pos.shape[0]*sim_pos.shape[1], sim_pos.shape[2]).cuda()
        sim_neg = torch.sum(query * key_neg, dim=-1)
        sim_neg = sim_neg.view(sim_neg.shape[0]*sim_neg.shape[1], sim_neg.shape[2]).cuda()

        #* define logits and labels
        #> logits info: [agents * horizon, pos/horizon + neg/horizon], type: tensor(:,:)
        #> labels: bunch of zeros indicating loss function to sum over batch (deprecated)
        logits = torch.cat([sim_pos, sim_neg], dim=1).cuda() / self.temperature
        labels = torch.zeros(len(logits), dtype=torch.long).cuda()

        #* compute loss and if isnan, due to the unfortunate agent selection, set to zero
        loss = self.criterion(logits, labels)
        loss = loss if not torch.isnan(loss) else torch.zeros(1).cuda()

        return loss


    def visualize_scenario(self, argo_map, scene_id, origin, city, trajs, pos_samples, neg_samples, save_dir, img_format='svg'):
        """
        Generates a figure with a binary map of driveable areas on the left,
            and lanes, trajectory predictions and contrastive samples on the right.
        params:
            argo_map: argoverse map
            scene_id: area identification, as gathered from data['idx']
            origin: scene center, as gathered from data['orig']
            city: 'MIA' > Miami or 'PIT' > Pittsburgh indicator
            trajs: agent trajectory predictions, tensor(n_agents, horizon, coords_xy)
            pos_samples: positive sample points, tensor(n_agents, horizon, n_samples, coords_xy)
            neg_samples: negative sample points, tensor(n_agents, horizon, n_samples, coords_xy)
            save_dir: string indicating desired path where the figure should be saved
            img_format: image file extension, typically 'png' or 'svg' depending on intended use

        return:
            None
        """
        #* define figure and color utility
        color = {
            'road':        '#A5A5A3',  # grey
            'main agent':  '#884DFF',  # purple
            'other agent': '#358EDB',  # blue
            'pos sample':  '#299438',  # green
            'neg sample':  '#FFA500',  # orange
        }
        _, (ax1, ax2) = plt.subplots(1, 2)

        #* define plot bounding box
        x0, y0 = origin[0].item(), origin[1].item()
        radius = 50
        x_min, x_max = x0 - radius, x0 + radius
        y_min, y_max = y0 - radius, y0 + radius

        #* ax1 generate binary map of road areas for positioning comparison
        # evaluate map grid points for offroad areas
        grid_pts = get_mesh_grid_as_point_cloud(x_min, x_max, y_min, y_max)
        offroad = ~argo_map.get_raster_layer_points_boolean(grid_pts, city, layer_name='driveable_area')
        # convert point 1d cloud to 2d grid for image preview
        ax1.imshow(np.flip(offroad.reshape(int(y_max - y_min) + 1, -1), axis=0), cmap='gray')

        #* ax1 plot settings
        # discard axis since its coordinates do not match reality
        ax1.set_title(f'Driveable Area')
        ax1.axis('off')


        #* ax2 plot map roads, agent trajectories and contrastive samples
        # map roads
        scene_roads = [argo_map.city_lane_centerlines_dict[city][id].centerline for id in argo_map.get_lane_ids_in_xy_bbox(x0, y0, city, radius)]
        for i, lane in enumerate(scene_roads):
            ax2.plot(
                lane[:, 0], lane[:, 1],
                linestyle='-', color=color['road'], linewidth=1,
                zorder=0, label='Road Lanes' if i == 0 else None
            )

        # agent trajectories
        agent_trajs = trajs.detach().cpu().numpy()
        for i, traj in enumerate(agent_trajs):
            ax2.plot(
                traj[:, 0], traj[:, 1],
                color=color['main agent'] if i == 0 else color['other agent'], alpha=0.9 if i == 0 else 0.6, linestyle="-", linewidth=2,
                zorder=10, label='Main Agent Traj' if i == 0 else 'Other Agent Trajs' if i == 1 else None,
            )
            ax2.arrow(
                traj[-2, 0], traj[-2, 1], traj[-1, 0] - traj[-2, 0], traj[-1, 1] - traj[-2, 1],
                color=color['main agent'] if i == 0 else color['other agent'], alpha=0.9 if i == 0 else 0.6, width=0.6
            )

        # contrastive samples
        pos = pos_samples.detach().cpu().numpy()
        ax2.scatter(
            pos[..., 0], pos[..., 1],
            color=color['pos sample'], marker='*', s=4,  # s is markersize for scatter
            zorder=1, label="Positive Samples"
        )
        neg = neg_samples.detach().cpu().numpy()
        ax2.scatter(
            neg[..., 0], neg[..., 1],
            color=color['neg sample'], marker='x', s=4,  # s is markersize for scatter
            zorder=-1, label="Negative Samples"
        )

        #* ax2 plot settings
        # align view frame and legend, note that axis limit hide missing data that is set at the origin
        ax2.set_title(f'Scene {scene_id} Preview')
        ax2.set(aspect='equal'); ax2.set_xlim(x_min, x_max); ax2.set_ylim(y_min, y_max)
        ax2.legend(prop={"size": "x-small"}, loc='upper center', bbox_to_anchor=(0.5, -0.2))#loc='center left', bbox_to_anchor=(1, 0.5))

        #* save figure, create directory if needed
        if not os.path.exists(save_dir[:save_dir.rfind('/')]):
            os.makedirs(save_dir[: save_dir.rfind('/')])

        plt.savefig(f'{save_dir}scene_id{scene_id}.{img_format}', bbox_inches='tight')
        plt.close()

        return
