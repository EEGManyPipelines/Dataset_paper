% Analysis of the EEGManyPipelines dataset for visualization purposes. 
% Step 3: correct for ocular artifacts by removing independent components
% showing high correlation with V/HEOG channels.
%
% See README.txt for further comments.

%% Silently load EEGLAB once to load all necessary paths. 
% Then wipe all the unnessesary variables.
addpath('../toolboxes/eeglab2021.0/');
addpath('./subfuncs/')
eeglab nogui; clear; close all

%% Set configuration.
cfg.dir_eeg_in  = './data/';
cfg.dir_eeg_out = './data/';

cfg.overwrite_clean = true;
cfg.VEOGchan        = 71;
cfg.HEOGchan        = 72;
cfg.corrthreshold   = 0.7; % Reject independent components correlating with V/HEOG channels.

%%
subjects = dir([cfg.dir_eeg_in '*ica.set']);

parpool(5)
parfor isub = 1:length(subjects)
% for isub = 1:length(subjects)
        
    name_str = sprintf('EMP_%02d_clean', isub); % subject index with trailing zero
    
    % Skip files that have already been recoded.
    if exist(fullfile(cfg.dir_eeg_out, [name_str '.set']), 'file') && cfg.overwrite_clean == false
        continue
    else
        
        % Load the dataset.        
        EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
        
        % Find ICA components correlated with EOG channels.        
        eog_chans = [cfg.HEOGchan, cfg.VEOGchan];
        badics = find_bad_ics(EEG, eog_chans, cfg.corrthreshold);        
        
        % Remove bad ICs from the original data. NOTE: the V/EOG channels
        % are not recomputed and will still show the original artifacts.
        EEG = pop_subcomp(EEG, badics, 0);
        
        % Save clean data.
        EEG = pop_editset(EEG, 'setname', name_str);                
        pop_saveset(EEG, 'filename', name_str, 'filepath', cfg.dir_eeg_out);
        
    end
end
disp('Done.')