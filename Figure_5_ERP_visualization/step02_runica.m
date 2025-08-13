% Analysis of the EEGManyPipelines dataset for visualization purposes.
% Step 2: run independent component analysis on preprocessed data.
%
% See README.txt for further comments.

%% Silently load EEGLAB once to load all necessary paths. 
% Then wipe all the unnessesary variables.
addpath('../toolboxes/eeglab2021.0/');
addpath('./subfuncs/')
eeglab nogui; clear; close all

%% Set configuration.
cfg.dir_eeg_in  = './data/';
cfg.dir_eeg_out  = './data/';

cfg.EEGchans = 1:70;
cfg.overwrite_ica = true;

%%
subjects = dir([cfg.dir_eeg_in '*prep.set']);

% ------------------------------------------------------------------------
% Set the random seed of the random number generator. Doing it this way is
% recommended instead of "rng" for parfor loops.
% ------------------------------------------------------------------------
parpool(6)
sc = parallel.pool.Constant(RandStream('Threefry'));

% for isub = 1%:length(subjects)
parfor isub = 1:length(subjects)

    name_str = sprintf('EMP_%02d_ica', isub); % subject index with trailing zero

    % Skip files that have already been recoded.
    if exist(fullfile(cfg.dir_eeg_in, [name_str '.set']), 'file') && cfg.overwrite_ica == false
        continue
    else
        
        % Load the dataset.        
        EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);        
        EEG.data = double(EEG.data); % Double gives more accurate ICA results.
        
        % --------------------------------------------------------------
        % Set the rng to a fixed value so that everybody always gets the
        % same results. The exact value does not matter, 3 is a lucky
        % number.
        % --------------------------------------------------------------
        stream = sc.Value;        % Extract the stream from the Constant
        stream.Substream = 1; % Set stream to constant value so that each parfor iteration uses same seed.
        
        % Run ICA.
        [EEG, com] = pop_runica(EEG, 'icatype', 'runica', ...
            'extended', 1, 'chanind', cfg.EEGchans);  
        
        % Save results.
        EEG.data = single(EEG.data);        
        EEG = pop_editset(EEG, 'setname', name_str);               
        pop_saveset(EEG, 'filename', name_str, 'filepath', cfg.dir_eeg_out);
    end
end

disp('Done.')