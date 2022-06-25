import matplotlib.pyplot as plt
import cv2
import numpy as np
import transforms3d
import math
import torch


def isOffRoad(points, city_name, am):
    if city_name == 'PIT':
        pit_binary_map = am.get_rasterized_driveable_area('PIT')[0]
        flipped_pit_binary = cv2.flip(pit_binary_map, 0)
        points = torch.tensor(points, dtype=torch.int32)
        X, Y = points[:, 0], points[:, 1]
        row_argo_numpy = flipped_pit_binary.shape[0] - Y
        col_argo_numpy = X

        row_numpy = row_argo_numpy - 214
        col_numpy = col_argo_numpy - 641

        values = flipped_pit_binary[row_numpy, col_numpy]
        off_roads = torch.where(torch.tensor(values) == 0, 1, 0)
        return off_roads.tolist()

    elif city_name == 'MIA':
        mia_binary_map = am.get_rasterized_driveable_area('MIA')[0]
        flipped_mia_binary = cv2.flip(mia_binary_map, 0)
        points = torch.tensor(points, dtype=torch.int32)
        X, Y = points[:, 0], points[:, 1]
        row_argo_numpy = flipped_mia_binary.shape[0] - Y
        col_argo_numpy = X

        row_numpy = row_argo_numpy + 543
        col_numpy = col_argo_numpy + 502

        values = flipped_mia_binary[row_numpy, col_numpy]
        off_roads = torch.where(torch.tensor(values) == 0, 1, 0)
        return off_roads.tolist()



# Tools for de-normalization
def transform_points(points: np.ndarray, transf_matrix: np.ndarray) -> np.ndarray:
    return transform_points_transposed(points.transpose(1, 0), transf_matrix).transpose(1, 0)


def transform_points_transposed(points: np.ndarray, transf_matrix: np.ndarray) -> np.ndarray:
    num_dims = transf_matrix.shape[0] - 1
    if points.shape[0] not in [2, 3, 4]:
        raise ValueError("Points input should be (2, N), (3,N) or (4,N) shape, received {}".format(points.shape))

    return transf_matrix.dot(np.vstack((points[:num_dims, :], np.ones(points.shape[1]))))[:num_dims, :]

def yaw_as_rotation33(yaw: float) -> np.ndarray:
    return transforms3d.euler.euler2mat(0, 0, yaw)

def argoverse_data_DeNormalization_batch(data_dic, normalized_data):
    """
    input:
    - data_dic: whole data of a batch including all features such as "history_positions" , "target_positions" , "yaw_deg" , "centroid"
    - nomalized_data: shape of [batch size = 32, future_points = 30, coordinates= 2]

    output: denormalized tensor of size [50,2] obtained from data["history_positions"] and data["target_positions"]
    """
    #agent_fullseq_norm = torch.cat([data["history_positions"] , data["target_positions"]], axis = 1)
    output = torch.empty((normalized_data.shape))
    for i in range(normalized_data.shape[0]):  #loop over batch
        rotated_yaw = transform_points(normalized_data[i,...], yaw_as_rotation33(-1 * math.pi * data_dic["yaw_deg"][i] / 180))
        denorm_sample_full_seq = torch.tensor(rotated_yaw) + data_dic["centroid"][i]  #shape=[30,2]
        output[i] = denorm_sample_full_seq.clone()
    return output


def argoverse_data_Normalization_horizon(De_normalized_data, centroid, yaw_deg):
    """
    input:
    - data_dic: whole data of a batch including all features such as "history_positions" , "target_positions" , "yaw_deg" , "centroid"
    - nomalized_data: shape of [neg_per_horizon= 10, horizon = 5, coordinates= 2]

    output: denormalized tensor of size [50,2] obtained from data["history_positions"] and data["target_positions"]
    """
    # agent_fullseq_norm = torch.cat([data["history_positions"] , data["target_positions"]], axis = 1)
    output = torch.empty((De_normalized_data.shape))
    for i in range(De_normalized_data.shape[0]):  # loop over batch
        rotated_yaw = transform_points(De_normalized_data[i, ...]  - np.array(centroid),
                                    yaw_as_rotation33(math.pi * yaw_deg / 180))
        denorm_sample_full_seq = torch.tensor(rotated_yaw)  # shape=[30,2]
        output[i] = denorm_sample_full_seq.clone()
    return output


#! modified normalisation and denormalisation suited to nce needs

def normalize_argoverse_data(denormalized_data, centroid, yaw_deg) -> torch.tensor:
    """
    input:
        - denormalized_data: tensor of x,y coordinates [N, 2]
        - centroid: tensor with centroid corresponding to these points (provided in data dict)
        - yaw_deg: tensor with rotation angle corresponding to these points (provided in data dict)

    output:
        - normalized tensor: transformed input denormalized_data [N,2]
    """
    return torch.tensor(
        transform_points(denormalized_data - centroid, yaw_as_rotation33(math.pi * yaw_deg / 180))
    )


def denormalize_argoverse_data(normalized_data, centroid, yaw_deg) -> torch.tensor:
    """
    input:
        - normalized_data: tensor of x,y coordinates [N, 2]
        - centroid: tensor with centroid corresponding to these points (provided in data dict)
        - yaw_deg: tensor with rotation angle corresponding to these points (provided in data dict)

    output:
        - denormalized tensor: transformed input normalized_data [N,2]
    """
    return centroid + torch.tensor(
        transform_points(
            normalized_data, yaw_as_rotation33(-1 * math.pi * yaw_deg / 180))
    )

#* continue (end of edits)