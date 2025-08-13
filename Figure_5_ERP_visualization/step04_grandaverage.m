% Analysis of the EEGManyPipelines dataset for visualization purposes.
% Step 4: compute grand averages for each experimental condition by
% selecting relevant trials and averaging data across subjects.
%
% See README.txt for further comments.

%% Silently load EEGLAB once to load all necessary paths. 
% Then wipe all the unnessesary variables.
addpath('../toolboxes/eeglab2021.0/');
addpath('./subfuncs/')
eeglab nogui; clear; close all; clc

%% Set configuration.
cfg.dir_eeg_in  = './data/';
cfg.dir_eeg_out = './data/';

cfg.VEOGchan = 71;
cfg.HEOGchan = 72;

%%
subjects = dir([cfg.dir_eeg_in '*clean.set']);

grand.conditions = {
    {'scene_category', 'manmade'}, {'scene_category', 'natural'};
    {'old', 'new'}, {'old', 'old'};
    {'behavior', 'hit'}, {'behavior', 'miss'};
    {'subsequent_memory', 'subsequent_forgotten'}, {'subsequent_memory', 'subsequent_remembered'};
    };

%%
eeginfo = pop_loadset('filename', subjects(1).name, ...
    'filepath', subjects(1).folder, ...
    'loadmode', 'info');

grand.data = nan(eeginfo.nbchan, eeginfo.pnts, length(subjects), size(grand.conditions,1), 2);


for isub = 1:length(subjects)

    name_str = sprintf('EMP_%02d_clean', isub); % subject index with trailing zero

    % Load the dataset.
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % Baseline correction.
    EEG = pop_rmbase(EEG, [EEG.times(1) 0]);

    % Average reference.
    EEG = pop_reref( EEG, [], 'keepref','on','exclude',[cfg.VEOGchan, cfg.HEOGchan] );

    % Extract trials for each condition.
    for icond = 1:size(grand.conditions,1)
        for ilevel = 1:2
            field  = grand.conditions{icond,ilevel}{1};     % e.g., 'old' or 'behavior'
            value  = grand.conditions{icond,ilevel}{2};     % e.g., 'old' or 'hit'
            trials = strcmp({EEG.event.(field)}, value);    % <-- note the curly braces

            % trials = strcmp([EEG.event.(grand.conditions{icond,ilevel}{1})], grand.conditions{icond,ilevel}{2});
            grand.data(:, :, isub, icond, ilevel) = mean(EEG.data(:,:,trials),3);
        end
    end

    is_old = strcmp({EEG.event.old}, 'old');
    is_hit = strcmp({EEG.event.behavior}, 'hit');
    grand.hit_rate(isub) = sum(is_hit & is_old) / sum(is_old);

    is_new = strcmp({EEG.event.old}, 'new');
    is_fa  = strcmp({EEG.event.behavior}, 'fa');   % or 'false_alarm' depending on your coding
    grand.fal_rate(isub)  = sum(is_fa & is_new) / sum(is_new);


    % grand.hit_rate(isub) = sum(strcmp([EEG.event.behavior], 'hit'))        / sum(strcmp([EEG.event.old], 'old'));
    % grand.fal_rate(isub) = sum(strcmp([EEG.event.behavior], 'falsealarm')) / sum(strcmp([EEG.event.old], 'new'));
    grand.dprime(isub)   = norminv(grand.hit_rate(isub)) - norminv(grand.fal_rate(isub));
end

grand.chanlocs = EEG.chanlocs;
grand.times = EEG.times;
grand.srate = EEG.srate;
save('grandaverage.mat', 'grand')

disp('Done.')