% Analysis of the EEGManyPipelines dataset for visualization purposes.
% Step 1: Resample, filter and epoch the continuous raw data, preparing the
% data for ICA.
%
% See README.txt for further comments.

%% Silently load EEGLAB once to load all necessary paths. 
% Then wipe all the unnessesary variables.
addpath('../toolboxes/eeglab2021.0/');
addpath('./subfuncs/')
eeglab nogui; clear; close all; clc
 
%% Set configuration.
cfg.dir_eeg_in     = '../../curate_EEG_data/OUT/eeg_eeglab/';
cfg.dir_eeg_out    = './data/';
cfg.overwrite_prep = true;

cfg.resample_freq  = 256;
cfg.hp_filt_cutoff = 0.1;
cfg.lp_filt_cutoff = 40;
cfg.epoch_lims     = [-0.5  1.0];

%% Preprocessing.
subjects = dir([cfg.dir_eeg_in '*.set']);
if ~exist(cfg.dir_eeg_out), mkdir(cfg.dir_eeg_out); end

parfor (isub = 1:length(subjects), 6)  

    name_str = sprintf('EMP_%02d_prep', isub); % subject index with trailing zero

    % Skip files that have already been recoded.
    if exist(fullfile(cfg.dir_eeg_out, [name_str '.set']), 'file') && cfg.overwrite_prep == false
        continue
    else

        % Load the dataset.
        EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

        EEG = pop_resample( EEG, cfg.resample_freq);
        EEG = pop_eegfiltnew(EEG, 'locutoff', cfg.hp_filt_cutoff);
        EEG = pop_eegfiltnew(EEG, 'hicutoff', cfg.lp_filt_cutoff);
        EEG = pop_epoch( EEG, {}, cfg.epoch_lims, 'newname', name_str, 'epochinfo', 'yes');

        % Save the data to disk under a new name.
        pop_saveset(EEG, 'filename', name_str, 'filepath', cfg.dir_eeg_out);
    end
end

disp('Done.')