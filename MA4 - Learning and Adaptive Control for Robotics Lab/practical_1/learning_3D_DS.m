%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is a template file to import 3D dataset to learn a DS from
% trajectories, and exporting the DS to be deployed on the real Panda
% robot. 
% You can use fonctions from chapter 3 to learn a DS using SEDS or LPVDS.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Import dependencies
close all; clear; clc
filepath = fileparts(which('learning_3D_DS.m'));
addpath(genpath(fullfile(filepath, '..', 'libraries', 'book-ds-opt')));
addpath(genpath(fullfile(filepath, '..', 'libraries', 'book-sods-opt')));
addpath(genpath(fullfile(filepath, '..', 'libraries', 'book-phys-gmm')));
addpath(genpath(fullfile(filepath, '..', 'libraries', 'book-thirdparty')));
addpath(genpath(fullfile(filepath, '..', 'libraries', 'book-robot-simulation')));
addpath(genpath(fullfile(filepath, 'dataset')));
cd(filepath);

%% Load and convert 3D dataset
% Import from the dataset folder either:
% - 'demonstration_dataset.mat'
% - 'MPC_train_dataset.mat'
% - 'MPC_test_dataset.mat'
% - 'theoretical_DS_dataset.mat'

% load("theoretical_DS_dataset.mat");
%load("MPC_train_dataset.mat");
load("demonstration_dataset.mat")
nTraj = size(trajectories, 3);
nPoints = size(trajectories, 2);

Data = zeros(6, nTraj*nPoints);
attractor = zeros(3, 1);
x0_all = zeros(3, nTraj);

for i = 1:nTraj
    Data(:,(i-1)*nPoints+1:i*nPoints) = trajectories(:,:,i);
    x0_all(:,i) = trajectories(1:3,1,i);
    attractor = attractor + trajectories(1:3,end,i);
end
attractor = attractor / nTraj;

% Normalizing dataset attractor position
M = size(Data, 1) / 2; 
Data(1:M,:) = Data(1:M,:) - attractor;
x0_all = x0_all - attractor;
att = [0; 0; 0];

% Plot position/velocity Trajectories
vel_samples = 50; vel_size = 0.75; 
[h_data, h_att, ~] = plot_reference_trajectories_DS(Data, att, vel_samples, vel_size);

% Extract Position and Velocities
M = size(Data,1) / 2;    
Xi_ref = Data(1:M,:);
Xi_dot_ref  = Data(M+1:end,:);   
axis_limits = axis;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%         ADD YOUR CODE BELOW TO LEARN 3D DS      %%
%% vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv %%
model = "SEDS"

if model == "SEDS"
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 2a (GMM FITTING): Fit GMM to Trajectory Data %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath(fullfile(filepath, '..', '..', 'libraries','book-sods-opt')));
addpath(genpath(fullfile(filepath, '..', '..', 'libraries','book-phys-gmm')));
addpath(genpath(fullfile(filepath, '..', '..', 'libraries','book-thirdparty')));

% 'seds-init': follows the initialization given in the SEDS code
est_options = [];
est_options.type        = 1;   % GMM Estimation Alorithm Type
est_options.maxK        = 15;  % Maximum Gaussians for Type 1/2
est_options.do_plots    = 1;   % Plot Estimation Statistics
est_options.fixed_K     = [];  % Fix K and estimate with EM
est_options.sub_sample  = 1;   % Size of sub-sampling of trajectories


% 0: Manually set the # of Gaussians
% 1: Do Model Selection with BIC
do_ms_bic = 0;

if do_ms_bic
    [Priors0, ~, ~] = fit_gmm([Xi_ref; Xi_dot_ref], [], est_options);
    nb_gaussians = length(Priors0);
else
    % Select manually the number of Gaussian components
    % Should be at least K=2, so that one is placed on around the attractor
    nb_gaussians = 3;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 2b (Optional - Initialize params for SEDS Solver): Initialize GMM parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_with_options = 0;

if ~init_with_options
    % Run Algorithm 1 from Chapter 3 (Get an initial guess by deforming Sigma's)
    [Priors0, Mu0, Sigma0] = initialize_SEDS([Xi_ref; Xi_dot_ref], nb_gaussians);
else
    % Run Algorithm 2 from Chapter 3 (Get an initial guess by optimizing
    % each K-th Gaussian function wrt. stability constraints independently
    clear init_options;
    init_options.tol_mat_bias  = 10^-4;
    init_options.tol_stopping  = 10^-10;
    init_options.max_iter      = 500;
    init_options.objective     = 'likelihood';
    [Priors0, Mu0, Sigma0] = initialize_SEDS([Xi_ref; Xi_dot_ref], nb_gaussians, init_options);
end

% Visualize Gaussian Components and labels on clustered trajectories
% Plot Initial Estimate
[~, est_labels] =  my_gmm_cluster([Xi_ref; Xi_dot_ref], Priors0, Mu0, Sigma0, 'hard', []);

% Visualize Estimated Parameters
visualizeEstimatedGMM(Xi_ref, Priors0, Mu0(1:M,:), Sigma0(1:M,1:M,:), est_labels, est_options);
title('GMM $\Theta_{GMR}=\{\pi_k,\mu^k,\Sigma^k\}$ Initial Estimate', 'Interpreter', 'LaTex');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 3 (DS ESTIMATION): RUN SEDS SOLVER  %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear options;
options.tol_mat_bias  = 10^-4;    % A very small positive scalar to avoid
                                  % instabilities in Gaussian kernel [default: 10^-1]
options.display       = 1;        % An option to control whether the algorithm
                                  % displays the output of each iterations [default: true]
options.tol_stopping  = 10^-10;   % A small positive scalar defining the stoppping
                                  % tolerance for the optimization solver [default: 10^-10]
options.max_iter      = 100;      % Maximum number of iteration for the solver [default: i_max=1000]
options.objective     = 'likelihood';  % 'mse'|'likelihood'
% options.objective     = 'mse';       % 'mse'|'likelihood'
sub_sample            = 1;             % sub-sample trajectories by this factor

% Running SEDS optimization solver
[Priors, Mu, Sigma] = SEDS_Solver(Priors0, Mu0, Sigma0,[Xi_ref(:,1:sub_sample:end); Xi_dot_ref(:,1:sub_sample:end)], options); 
clear ds_seds
ds_seds = @(x) GMR_SEDS(Priors, Mu, Sigma, x - repmat(att,[1 size(x,2)]), 1:M, M+1:2*M);

%% %%%%%%%%%%%%    Plot Resulting DS  %%%%%%%%%%%%%%%%%%%
% Fill in plotting options
ds_plot_options = [];
ds_plot_options.sim_traj  = 1;            % To simulate trajectories from x0_all
ds_plot_options.x0_all    = x0_all;       % Intial Points
ds_plot_options.init_type = 'ellipsoid';  % For 3D DS, to initialize streamlines
                                          % 'ellipsoid' or 'cube'
ds_plot_options.nb_points = 30;           % No of streamlines to plot (3D)
ds_plot_options.plot_vol  = 1;            % Plot volume of initial points (3D)

[~, hs, hr, x_sim] = visualizeEstimatedDS(Data(1:M,:), ds_seds, ds_plot_options);
scatter(att(1), att(2), 150, [0 0 0], 'd', 'Linewidth', 2); hold on;
limits = axis;
switch options.objective
    case 'mse'
        title('SEDS $J(\theta_{GMR})$=MSE', 'Interpreter', 'LaTex','FontSize', 30)
    case 'likelihood'
        title('SEDS $J(\theta_{GMR})$=Likelihood', 'Interpreter', 'LaTex', 'FontSize', 30)
end
set(gcf,'Position', [158 389 446 348])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 4 (Evaluation): Compute Metrics and Visualize Velocities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
disp('--------------------')

% Compute RMSE on training data
rmse = mean(rmse_error(ds_seds, Xi_ref, Xi_dot_ref));
fprintf('SEDS got velocity RMSE on training set: %d \n', rmse);

% Compute e_dot on training data
edot = mean(edot_error(ds_seds, Xi_ref, Xi_dot_ref));
fprintf('SEDS got velocity deviation (e_dot) on training set: %d \n', edot);

% Compute DTWD between train trajectories and reproductions
if ds_plot_options.sim_traj
    nb_traj       = size(x_sim, 3);
    ref_traj_leng = size(Xi_ref, 2) / nb_traj;
    dtwd = zeros(1, nb_traj);
    for n=1:nb_traj
        start_id = round(1 + (n-1) * ref_traj_leng);
        end_id   = round(n * ref_traj_leng);
        dtwd(1,n) = dtw(x_sim(:,:,n)', Data(1:M,start_id:end_id)', 20);
    end
end
fprintf('SEDS got reproduction DTWD on training set: %2.4f +/- %2.4f \n', mean(dtwd), std(dtwd));

% Compare Velocities from Demonstration vs DS
h_vel = visualizeEstimatedVelocities(Data, ds_seds);
end



if model == "LPVDS"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 2 (GMM FITTING): Fit GMM to Trajectory Data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath(fullfile(filepath, '..', '..', 'libraries','book-sods-opt')));
addpath(genpath(fullfile(filepath, '..', '..', 'libraries','book-phys-gmm')));
addpath(genpath(fullfile(filepath, '..', '..', 'libraries','book-thirdparty')));

%%%%%%%%%%%%%%%%%% GMM Estimation Algorithm %%%%%%%%%%%%%%%%%%%%%%

% 0: Physically-Consistent Non-Parametric (Collapsed Gibbs Sampler)
% 1: GMM-EM Model Selection via BIC
% 2: CRP-GMM (Collapsed Gibbs Sampler)
est_options = [];
est_options.type             = 1;   % GMM Estimation Algorithm Type 

% If algo 1 selected:
est_options.maxK             = 10;  % Maximum Gaussians for Type 1
est_options.fixed_K          = [];  % Fix K and estimate with EM for Type 1

% If algo 0 or 2 selected:
est_options.samplerIter      = 50;  % Maximum Sampler Iterations
                                    % For type 0: 20-50 iter is sufficient
                                    % For type 2: >100 iter are needed
                                    
est_options.do_plots         = 1;   % Plot Estimation Statistics
% Size of sub-sampling of trajectories
% 1/2 for 2D datasets, >2/3 for real
nb_data = length(Data);
sub_sample = 1;
if nb_data > 500
    sub_sample = 2;
elseif nb_data > 1000
    sub_sample = 3;
end
est_options.sub_sample       = sub_sample;

% Metric Hyper-parameters
est_options.estimate_l       = 1;   % '0/1' Estimate the lengthscale, if set to 1
est_options.l_sensitivity    = 2;   % lengthscale sensitivity [1-10->>100]
                                    % Default value is set to '2' as in the
                                    % paper, for very messy, close to
                                    % self-intersecting trajectories, we
                                    % recommend a higher value
est_options.length_scale     = [];  % if estimate_l=0 you can define your own
                                    % l, when setting l=0 only
                                    % directionality is taken into account

% Fit GMM to Trajectory Data
[Priors, Mu, Sigma] = fit_gmm(Xi_ref, Xi_dot_ref, est_options);

%% Generate GMM data structure for DS learning
clear ds_gmm; ds_gmm.Mu = Mu; ds_gmm.Sigma = Sigma; ds_gmm.Priors = Priors; 

% (Recommended!) Step 2.1: Dilate the Covariance matrices that are too thin
% This is recommended to get smoother streamlines/global dynamics
adjusts_C  = 1;
if adjusts_C  == 1
    if M == 2
        tot_dilation_factor = 1; rel_dilation_fact = 0.25;
    elseif M == 3
        tot_dilation_factor = 1; rel_dilation_fact = 0.75;
    end
    Sigma_ = adjust_Covariances(ds_gmm.Priors, ds_gmm.Sigma, tot_dilation_factor, rel_dilation_fact);
    ds_gmm.Sigma = Sigma_;
end

%  Visualize Gaussian Components and labels on clustered trajectories 
% Extract Cluster Labels
[~, est_labels] =  my_gmm_cluster(Xi_ref, ds_gmm.Priors, ds_gmm.Mu, ds_gmm.Sigma, 'hard', []);

% Visualize Estimated Parameters
visualizeEstimatedGMM(Xi_ref, ds_gmm.Priors, ds_gmm.Mu, ds_gmm.Sigma, est_labels, est_options);
title('GMM PDF contour ($\theta_{\gamma}=\{\pi_k,\mu^k,\Sigma^k\}$). Initial Estimate','Interpreter','LaTex');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 3 (DS ESTIMATION): ESTIMATE SYSTEM DYNAMICS MATRICES  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% DS OPTIMIZATION OPTIONS %%%%%%%%%%%%%%%%%%%%%% 
% Type of constraints/optimization 
constr_type = 1;      % 0:'convex':     A' + A < 0 (Proposed in paper)
                      % 1:'non-convex': A'P + PA < 0 (Sina's Thesis approach - not suitable for 3D)
                      % 2:'non-convex': A'P + PA < -Q given P (Proposed in paper)                                 
init_cvx    = 1;      % 0/1: initialize non-cvx problem with cvx     

if constr_type == 0 || constr_type == 1
    P_opt = eye(M);
else
    % P-matrix learning
%     [Vxf] = learn_wsaqf(Data,0,att);
   
    % (Data shifted to the origin)
    % Assuming origin is the attractor (works better generally)
    [Vxf] = learn_wsaqf(Data);
    P_opt = Vxf.P;
end

%%%%%%%%  LPV system sum_{k=1}^{K}\gamma_k(xi)(A_kxi + b_k) %%%%%%%%  
if constr_type == 1
    [A_k, b_k, P_est] = optimize_lpv_ds_from_data(Data, zeros(M,1), constr_type, ds_gmm, P_opt, init_cvx);
    ds_lpv = @(x) lpv_ds(x-repmat(att, [1 size(x,2)]), ds_gmm, A_k, b_k);
else
    [A_k, b_k, P_est] = optimize_lpv_ds_from_data(Data, att, constr_type, ds_gmm, P_opt, init_cvx);
    ds_lpv = @(x) lpv_ds(x, ds_gmm, A_k, b_k);
end

%% %%%%%%%%%%%%    Plot Resulting DS  %%%%%%%%%%%%%%%%%%%
% Fill in plotting options
ds_plot_options = [];
ds_plot_options.sim_traj  = 1;            % To simulate trajectories from x0_all
ds_plot_options.x0_all    = x0_all;       % Intial Points
ds_plot_options.init_type = 'ellipsoid';  % For 3D DS, to initialize streamlines
                                          % 'ellipsoid' or 'cube'
ds_plot_options.nb_points = 30;           % No of streamlines to plot (3D)
ds_plot_options.plot_vol  = 1;            % Plot volume of initial points (3D)

[hd, hs, hr, x_sim] = visualizeEstimatedDS(Xi_ref, ds_lpv, ds_plot_options);
limits = axis;
switch constr_type
    case 0
        title('GMM-based LPV-DS with QLF', 'Interpreter', 'LaTex', 'FontSize', 20)
    case 1
        title('GMM-based LPV-DS with P-QLF (v0) ', 'Interpreter', 'LaTex', 'FontSize', 20)
    case 2
        title('GMM-based LPV-DS with P-QLF', 'Interpreter', 'LaTex', 'FontSize', 20)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 5 (Evaluation): Compute Metrics and Visualize Velocities %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
disp('--------------------')

% Compute RMSE on training data
rmse = mean(rmse_error(ds_lpv, Xi_ref, Xi_dot_ref));
fprintf('LPV-DS with (O%d), got velocity RMSE on training set: %d \n', constr_type+1, rmse);

% Compute e_dot on training data
edot = mean(edot_error(ds_lpv, Xi_ref, Xi_dot_ref));
fprintf('LPV-DS with (O%d), got velocity deviation (e_dot) on training set: %d \n', constr_type+1, edot);

% Compute DTWD between train trajectories and reproductions
if ds_plot_options.sim_traj
    nb_traj       = size(x_sim, 3);
    ref_traj_leng = size(Xi_ref, 2) / nb_traj;
    dtwd = zeros(1, nb_traj);
    for n=1:nb_traj
        start_id = round(1 + (n-1) * ref_traj_leng);
        end_id   = round(n * ref_traj_leng);
        dtwd(1,n) = dtw(x_sim(:,:,n)', Xi_ref(:,start_id:end_id)', 20);
    end
    fprintf('LPV-DS got DTWD of reproduced trajectories: %2.4f +/- %2.4f \n', mean(dtwd), std(dtwd));
end

% Compare Velocities from Demonstration vs DS
h_vel = visualizeEstimatedVelocities(Data, ds_lpv);    
end

%% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %%
%%         ADD YOUR CODE ABOVE TO LEARN 3D DS      %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%% Save DS for simulation using 'DS_control.m'
usingSEDS = true;

if usingSEDS
    ds_control = @(x) ds_seds(x - attractor);
    save('ds_control.mat', "ds_control", "attractor", "Priors", "Mu", "Sigma", "att", "M")
else
    ds_control = @(x) ds_lpv(x - attractor);
    save('ds_control.mat', "ds_control", "attractor", "ds_gmm", "A_k", "b_k", "att")
end

