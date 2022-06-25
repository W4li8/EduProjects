import random
import torch
import numpy as np

from argoverse.utils.mesh_grid import get_mesh_grid_as_point_cloud


class EventSampler():
    """ Different argoverse map sampling strategies for social contrastive learning. """

    def __init__(self):
        """ Defines contrastive trajectory sampling strategies available to the user for SocialNCE (see ReadMe). """

        #* positive sampling strategies to choose from
        self.pos_sampling = {
            "truth": self.sample_pos_truth,  # ground truth trajectory
            "noisy": self.sample_pos_noisy,  # noisy ground truth trajectory
        }
        #* negative sampling strategies to choose from
        self.neg_sampling = {
            "offroad_expand": self.sample_neg_offroad_expand,  # nearby offroad points from scaling zone
            "offroad_cloud": self.sample_neg_offroad_cloud,    # nearby offroad points from grid point cloud
        }


    def sample_pos_truth(self, info, trajs, gt_trajs, n_samples, argo_map):
        """
        Returns the ground truth as positive samples, one positive sample per horizon only.
        @params:
            gt_trajs: ground truth trajectories, tensor(n_agents, horizon, coords_xy)
            others ignored (present for sampling function call consistency)

        @return:
            pos_samples: ground truth trajectories, tensor(n_agents, horizon, n_samples=1, coords_xy)
        """

        _ = info, trajs, n_samples, argo_map
        # return reshaped ground truth
        pos_samples = gt_trajs[:, :, None, :]

        return pos_samples


    def sample_pos_noisy(self, info, trajs, gt_trajs, n_samples, argo_map):
        """
        Returns the ground truth with added noise as positive samples, one positive sample per horizon only.
        @params:
            gt_trajs: ground truth trajectories, tensor(n_agents, horizon, coords_xy)
            others ignored (present for sampling function call consistency)

        @return:
            pos_samples: noisy ground truth trajectories, tensor(n_agents, horizon, n_samples=1, coords_xy)
        """

        _ = info, trajs, n_samples, argo_map
        # generate and add noise to reshaped ground truth
        noise = 0.5 * torch.rand(trajs[:, :, None, :].size()).sub(0.5).cuda()  # ~ 0.5 meters
        pos_samples = gt_trajs[:, :, None, :] + noise

        return pos_samples


    def sample_neg_offroad_cloud(self, info, trajs, gt_trajs, n_samples, argo_map):
        """
        Returns the ground truth with added noise as positive samples, one positive sample per horizon only.
        @params:
            info: city 'MIA' > Miami or 'PIT' > Pittsburgh indicator, and trajectory normalisation details (ignored)
            trajs: predicted trajectories, tensor(n_agents, horizon, coords_xy)
            n_samples: number of negative samples desired
            argo_map: argoverse map
            others ignored (present for sampling function call consistency)

        @return:
            neg_samples: n_samples nearest points found in the surrounding grid point cloud, tensor(n_agents, horizon, n_samples, coords_xy)
                defaults to zero if not enough were found
        """

        (cities, *_), _ = info, gt_trajs
        n_agents, horizon, coords = trajs.shape

        #* generate n_samples of xy coords per agent per time
        agent_trajs = trajs.detach().cpu().numpy()  # copy data to cpu for numpy
        neg_samples = torch.zeros((n_agents, horizon, n_samples, coords))
        search_radius = 3  # distance in meters
        for i in range(n_agents):
            for j in range(horizon):
                position = agent_trajs[i, j]
                x_min, y_min = position - search_radius
                x_max, y_max = position + search_radius

                ## generate a point cloud around position (~ 4*search_radius^2 points)
                grid_pts = get_mesh_grid_as_point_cloud(x_min, x_max, y_min, y_max)
                offroad = ~argo_map.get_raster_layer_points_boolean(grid_pts, cities[i], 'driveable_area')
                #* select points of greater interest
                #> sort offroad points by euclidian distance and keep closest n_samples
                #> samples default to origin if not enough are found within a search radius
                idx = np.argsort(np.sum((position - grid_pts[offroad])**2, axis=1))[:n_samples]
                neg_samples[i, j, :len(idx)] = torch.from_numpy(grid_pts[offroad][idx])

        return neg_samples


    def sample_neg_offroad_expand(self, info, trajs, gt_trajs, n_samples, argo_map):
        """
        Returns the ground truth with added noise as positive samples, one positive sample per horizon only.
        @params:
            info: city 'MIA' > Miami or 'PIT' > Pittsburgh indicator, and trajectory normalisation details (ignored)
            trajs: predicted trajectories, tensor(n_agents, horizon, coords_xy)
            n_samples: number of negative samples desired
            argo_map: argoverse map
            others ignored (present for sampling function call consistency)

        @return:
            neg_samples: random selection of n_sample points found by scaling a circular area around the agent tensor(n_agents, horizon, n_samples, coords_xy)
                keeps scaling area until n_samples are found
        """

        (cities, *_), _ = info, gt_trajs
        n_agents, horizon, coords = trajs.shape

        #* generates points around origin, used to augment sampling data
        agent_zone = np.array([[np.cos(np.deg2rad(x)), np.sin(np.deg2rad(x))] for x in range(0, 360, 24)])

        #ToDo: inefficient implementation but it works - optimise a little? (no time to explore now)
        #* generate n_samples of xy coords per agent per time
        agent_trajs = trajs.detach().cpu().numpy()  # copy data to cpu for numpy
        neg_samples = torch.zeros((n_agents, horizon, n_samples, coords))
        for i in range(n_agents):
            for t in range(horizon):
                neg_samples_it = []  # list of samples through scaling iterations at a given time
                scale = 2  # sampling proximity scale
                #* find nearby offroad points in a circular fashion
                #> keep increasing scale until n_samples are found
                while len(neg_samples_it) < n_samples:
                    scale += 1
                    ## generate close by points (agent zone in init)
                    neg_samples_tmp = agent_trajs[i, t][None, :] + np.round(scale * agent_zone)
                    ## keep those that are offroad
                    offroad = ~argo_map.get_raster_layer_points_boolean(neg_samples_tmp, cities[i], 'driveable_area')
                    neg_samples_it += neg_samples_tmp[np.where(offroad)].tolist()

                #* select and store points of interest
                #> could be that too many offroad samples were generated, keep n_samples at random
                neg_samples[i, t, :, :] = torch.tensor(random.sample(neg_samples_it, n_samples))

        return neg_samples
