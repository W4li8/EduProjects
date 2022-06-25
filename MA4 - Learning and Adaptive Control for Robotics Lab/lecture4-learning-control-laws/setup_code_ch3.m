function setup_code_ch3(varargin)
% Get folder path
folder_path = fileparts(which('setup_code_ch3.m'));

% remove any auxiliary folder from the search path
restoredefaultpath();

% remove the default user-specific path
userpath('clear');

% Install toolboxes in ML_toolbox
libsvm_path = fullfile(folder_path, '..', 'libraries', 'book-ml-toolbox', 'methods', 'toolboxes', 'libsvm', 'matlab');
cd(libsvm_path);
run('make.m')

% IF NOT WORKING FOR WINDOWS PC, MEX with a compiler needs to be configured = install compiler
% Install lightspeed
lightspeed_path = fullfile(folder_path, '..', 'libraries', 'book-thirdparty', 'lightspeed');
cd(lightspeed_path);
% If error here, mex compiler has to be setup "mex -setup"
install_lightspeed
test_lightspeed
cd(folder_path);

% Install sedumi
sedumi_path = fullfile(folder_path, '..', 'libraries', 'book-thirdparty', 'sedumi');
cd(sedumi_path);
% If error here run "install_sedumi -build"
install_sedumi
cd(folder_path);

close all;

end
