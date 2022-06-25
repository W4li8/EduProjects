from argoverse.visualization.visualize_sequences import viz_sequence
from argoverse.map_representation.map_api import ArgoverseMap
from argoverse.data_loading.argoverse_forecasting_loader import ArgoverseForecastingLoader
import matplotlib.pyplot as plt
import cv2
import numpy as np
import pandas as pd
import copy
import matplotlib.pyplot as plt
from argodataset.demo_usage.visualize_30hz_benchmark_data_on_map import DatasetOnMapVisualizer
from src.argoverse.utils.baseline_utils import get_abs_traj


def showRoadMap(history,future,neg_samples,data_dir,city_name,th):
  experiment_prefix = 'visualization_demo'

  domv = DatasetOnMapVisualizer(data_dir,experiment_prefix, use_existing_files=True, log_id=0)
  # (679,-201) is the coordinate of buttom left of rasterized image
  fig = plt.figure(figsize=(10,10))
  ax = fig.add_subplot(111)
  # xcenter,ycenter,_ = 2169,821,0
    
  xmin = history[19,0] - th  # 150
  xmax = history[19,0] + th  # 150
  ymin = history[19,1] - th  # 150
  ymax = history[19,1] + th  # 150

  size = 100

  if history is not None:
    for point in history:
      ax.scatter(point[0], point[1], size, color="g", marker=".", zorder = 1)

  if future is not None:
    for point in future:
      ax.scatter(point[0], point[1], size, color="b", marker=".", zorder = 1)

  if neg_samples is not None:
    for point in neg_samples:
      ax.scatter(point[0], point[1], size, color="r", marker=".", zorder = 1)


  ax.scatter(history[19,0], history[19,1], 200, color="black", marker=".", zorder=1)

  ax.set_xlim([xmin, xmax])
  ax.set_ylim([ymin, ymax])
  local_lane_polygons = am.find_local_lane_polygons([xmin, xmax, ymin, ymax], city_name)
  local_das = am.find_local_driveable_areas([xmin, xmax, ymin, ymax], city_name)

  result = domv.render_bev_labels_mpl(
      city_name,
      ax,
      "city_axis",
      None,
      copy.deepcopy(local_lane_polygons),
      copy.deepcopy(local_das),
      0,
      new_data['TIMESTAMP'],
      [history[19,0], history[19,1]],
      am
  )

  return result




def showBinaryMap(history,future,negative_samples,city_name,th,am):

  pit_binary_map = am.get_rasterized_driveable_area('PIT')[0]
  mia_binary_map = am.get_rasterized_driveable_area('MIA')[0]
  flipped_pit_binary = cv2.flip(pit_binary_map,0)
  flipped_mia_binary =  cv2.flip(mia_binary_map,0) 

  if city_name == 'PIT':
    flipped_rasterized_image = flipped_pit_binary.copy()
    flipped_rasterized_image = np.where(flipped_rasterized_image == 1,255,0).astype(np.uint8)
    flipped_rasterized_image = cv2.cvtColor(flipped_rasterized_image,cv2.COLOR_GRAY2RGB)

    points = np.concatenate([history,future,negative_samples],axis=0)

    min_x = 9999
    min_y = 9999
    max_x = -9999
    max_y = -9999

    for i,pt in enumerate(points):

      x_argo,y_argo = points[i,0],points[i,1]
      row_argo_numpy = flipped_rasterized_image.shape[0] - y_argo
      col_argo_numpy = x_argo

      row_numpy = row_argo_numpy - 214
      col_numpy = col_argo_numpy - 641

      if row_numpy < min_x:
        min_x = row_numpy
      
      if row_numpy > max_x:
        max_x = row_numpy

      if col_numpy < min_y:
        min_y = col_numpy

      if col_numpy > max_y:
        max_y = col_numpy

      min_x = int(min_x)
      min_y = int(min_y)
      max_x = int(max_x)
      max_y = int(max_y)

      center_coordinates = (int(col_numpy), int(row_numpy))
      radius = 1

      if i<20:
        color = (0, 255, 0)
      elif i>=20 and i<50:
        color = (0, 0, 255)
      else:
        color = (255, 0, 0)


      thickness = -1
      flipped_rasterized_image = cv2.circle(flipped_rasterized_image, center_coordinates, radius, color, thickness)
    plt.figure(figsize=(8,8))
    plt.imshow(flipped_rasterized_image[min_x-th:max_x+th,min_y-th:max_y+th,:],'gray')

  elif city_name == 'MIA':
    flipped_rasterized_image = flipped_mia_binary.copy()
    flipped_rasterized_image = np.where(flipped_rasterized_image == 1,255,0).astype(np.uint8)
    flipped_rasterized_image = cv2.cvtColor(flipped_rasterized_image,cv2.COLOR_GRAY2RGB)

    points = np.concatenate([history,future,negative_samples],axis=0)

    min_x = 9999
    min_y = 9999
    max_x = -9999
    max_y = -9999

    for i in range(len(points)):

      x_argo,y_argo = points[i,0],points[i,1]
      row_argo_numpy = flipped_rasterized_image.shape[0] - y_argo
      col_argo_numpy = x_argo

      row_numpy = row_argo_numpy + 543
      col_numpy = col_argo_numpy + 502

      if row_numpy < min_x:
        min_x = row_numpy
      
      if row_numpy > max_x:
        max_x = row_numpy

      if col_numpy < min_y:
        min_y = col_numpy

      if col_numpy > max_y:
        max_y = col_numpy

      min_x = int(min_x)
      min_y = int(min_y)
      max_x = int(max_x)
      max_y = int(max_y)

      center_coordinates = (int(col_numpy), int(row_numpy))
      # print(center_coordinates)
      radius = 1

      if i<20:
        color = (0, 255, 0)
      elif i>=20 and i<50:
        color = (0, 0, 255)
      else:
        color = (255, 0, 0)

      thickness = -1
      flipped_rasterized_image = cv2.circle(flipped_rasterized_image, center_coordinates, radius, color, thickness)
    plt.figure(figsize=(8,8))
    plt.imshow(flipped_rasterized_image[min_x-th:max_x+th,min_y-th:max_y+th,:],'gray')
    pass

  else:
    raise Exception('City name is not recogniz ed')







def showMapsCenterLine(data,root_path,types):
  data = data.values
  new_dataset = []
  columns = ['TIMESTAMP','TRACK_ID','OBJECT_TYPE','X','Y','CITY_NAME']

  # one = np.array([315970999.4840635,'00000000-0000-0000-0000-000000014752','OTHERS',1700,350.,'PIT'],dtype=object).reshape(1,6)
  # two = np.array([315970999.4840635,'00000000-0000-0000-0000-000000014753','OTHERS',2100,650,'PIT'],dtype=object).reshape(1,6)
  # three = np.array([315970999.4840635,'00000000-0000-0000-0000-000000014754','OTHERS',200,3000,'PIT'],dtype=object).reshape(1,6)

  # new_dataset.append(one)
  # new_dataset.append(two)
  # new_dataset.append(three)

  for i in range(len(data)):
    if data[i,2] in types:
      new_dataset.append(np.expand_dims(data[i,:],axis=0))

  new_dataset = np.concatenate(new_dataset,axis=0)
  new_dataset = pd.DataFrame(new_dataset)  
  new_dataset.columns = columns
  new_dataset.to_csv(root_path+'1.csv')
  

  x_min = int(min(new_dataset["X"]))
  x_max = int(max(new_dataset["X"]))
  y_min = int(min(new_dataset["Y"]))
  y_max = int(max(new_dataset["Y"]))

  print(x_min,
        x_max,
        y_min,
        y_max)


  arg = ArgoverseForecastingLoader(root_path)
  seq_path = f'{root_path}1.csv'
  viz_sequence(arg.get(seq_path).seq_df, show=True)

  return new_dataset




def plotDataOnMap(data,args,helpers,type):

  history_main_agent = data['history_positions']
  GT_main_agent = data['target_positions']
  # history = history_others[10,...]
  # future = GT_main_agent[10,...]   
  history = np.expand_dims(history_main_agent[10,:,:],axis=0)
  future = np.expand_dims(GT_main_agent[10,:,:],axis=0)

  input,output = get_abs_traj(
                              history,
                              future,
                              args,
                              helpers)

  showBinaryMap(input[0,:,:],flipped_rasterized_image,city_name,th)