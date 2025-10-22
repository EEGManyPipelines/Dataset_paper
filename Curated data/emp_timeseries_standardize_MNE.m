% The code uses the processed epoched EEG time series data submitted by teams in
% varying file formats (e.g., .mat) and standardizes it by applying
% the same window length, number of channels, order of channels, and
% sampling rate.

% Prepared in 27.09.2024 by EEGManyPipelines Steering Committee members
% Elena Cesnaite, Johannes Algermissen, Andrea Vitale
clear all, close all
addpath C:\Users\ecesnait\Desktop\EEGManyPipelines\git\EEGManyPipes org\Main_Paper\johannes\timeseries\

% ----------------------------------------------------------------------- %
%% Set up directories:
dirs = [];
dirs.data       = fullfile('M:\EMP\EEGManyPipelines\EMP time series exp\');
dirs.saveDirstand = 'M:\EMP\EEGManyPipelines\EMP time series exp\Standardized\'
dirs.saveDiravg = 'M:\EMP\EEGManyPipelines\EMP time series exp\TimelockAVG\'

% ----------------------------------------------------------------------- %
%% Add fieldtrip toolbox:

dirs.fieldtrip = 'C:\Users\ecesnait\Desktop\EEGManyPipelines\Matlab Scripts\toolboxes\fieldtrip-master\';
if ~contains(lower(path), lower(fullfile(dirs.fieldtrip)))
    fprintf('Add Fieldtrip\n');
    addpath(dirs.fieldtrip);
end

cd(dirs.fieldtrip)

ft_defaults;
global ft_default;
ft_default.showlogo = 'no';

% ----------------------------------------------------------------------- %
%% Set input settings:

% Desired time settings:
FS              = 256; % sampling rate in Hz
timeWindow      = [-200 600]; % consistent trial epoching (in ms)
timeVec_standard1 = flip([ 0 : -1/FS*1000 : timeWindow(1) ]);
timeVec_standard2        = [ 0 : 1/FS*1000 : timeWindow(2) ];
timeVec_standard         = [ timeVec_standard1(1:end-1), timeVec_standard2 ];
nTimeDes        = length(timeVec_standard); % number desired time bins

% Expected channels:
allChanVec      = {...
    'AF3', 'AF4', 'AF7', 'AF8', 'AFz', 'Afp10', 'Afp9', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', ...
    'CP1', 'CP2', 'CP3', 'CP4', 'CP5', 'CP6', 'CPz', 'Cz', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', ...
    'F7', 'F8', 'FC1', 'FC2', 'FC3', 'FC4', 'FC5', 'FC6', 'FCz', 'FT7', 'FT8', 'Fp1', 'Fp2', ...
    'Fpz', 'Fz', 'HEOG', 'IO1', 'IO2', 'Iz', 'M1', 'M2', 'O1', 'O2', 'Oz', 'P1', 'P10', 'P2', ...
    'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'PO3', 'PO4', 'PO7', 'PO8', 'POz', 'Pz', 'T7', ...
    'T8', 'TP7', 'TP8', 'VEOG' ...
    }; % extract original channels, sorted alphabetically
nonEEGChanVec   = {'Afp10', 'Afp9', 'HEOG', 'IO1', 'IO2', 'M1', 'M2', 'VEOG'}; % channels 65-72 in dataset documentation
eegChanVec      = allChanVec(~ismember(allChanVec, nonEEGChanVec)); % EEG channels
nChan           = length(eegChanVec);

% ----------------------------------------------------------------------- %
%% Detect input data, set settings:

% Detect all files:

fprintf('*** Search for files');
allDat = dir(fullfile(dirs.data));
allDatFol = allDat([allDat.isdir]);
teamList    = {allDatFol.name};
indx_exclude_folder  = find(ismember(teamList, {'.','..','_fieldtrip_data3d', 'TimelockAVG', 'EEGLAB all teams', 'Continuous_to_epoched', 'Standardized'}))
teamList(indx_exclude_folder) = []; % exclude folders that we are not interested in
nTeam       = length(teamList);
fprintf('*** Found %d files:\n%s ***\n', nTeam, strjoin(teamList, ', '));

% ----------------------------------------------------------------------- %
%% Loop over teams:

for iTeam = 1:nTeam %

    alldatstand = cell(1,nTeam)

    fprintf('*** ========================================================== ***\n');
    fprintf('*** TEAM %s: Start loading data ...  ***\n', teamList{iTeam});
    rawDataFolder         = fullfile(dirs.data, teamList{iTeam});
    rawDataFiles = dir([rawDataFolder, '\*.mat'])
    nsub = length(rawDataFiles)

    fprintf('*** Team %s: Found data from %02d subjects ***\n', teamList{iTeam}, nsub);

    % Load subject data by looping through all the subjects found in the
    % folder. We will have to average across them.
    for iSub = 1:nsub

        rawData = load(fullfile(rawDataFolder, rawDataFiles(iSub).name))
        fprintf('*** ... finished :-) ***\n');

        % If data is not epoched - skip it.
        if numel(size(rawData.data)) < 3 %check how many dimensions EEGts has. if it's conitnuous data, skip it:
            fprintf('*** Team %s: the EEG data is not epoched', teamList{iTeam});
            clear rawData
            continue
        end

        clear data4
        fprintf('*** --------------------------------------------- ***\n');
        fprintf('*** Subject %02d: START ***\n', iSub);

        % Extract data dimensions:
        nChanFound = []
        nChanFound          = size(rawData.data, 1);
        nTimeFound          = size(rawData.data, 2);
        nTrialFound         = size(rawData.data, 3);
        fprintf('*** Subject %02d: Found data from %d channels, %d time points, %d trials ***\n', ...
            iSub, nChanFound, nTimeFound, nTrialFound);

        if isempty(rawData.data) % if data is empty, skip it
            fprintf('*** Subject %02d: Data is empty, skip subject ***\n', iSub);
            continue
        end

        %% Keep only the selected channels

        if size(rawData.data,1) <=74 % first dimention should be channels
            indx_chan = [];
            indx_chan = ismember(rawData.chs_name, eegChanVec);
            rawData.chs_name = rawData.chs_name(indx_chan);
            rawData.data = rawData.data(indx_chan,:,:);

        else
            error('Insnpect dimentions')
        end

        % --------------------------------------------------------------- %
        %% Create Fieldtrip structure:

        fprintf('*** Subject %02d: Cast into Fieldtrip structure ***\n', iSub);
        data1                   = []; % initialize
        data1.dimord            = 'chan_time'; % dimension order for each trial
        timeVecFound            = rawData.time; % extract time bin labels

        if (timeVecFound(end) - timeVecFound(1)) < 10 % convert from sec to ms
            timeVecFound = timeVecFound * 1000
            rawData.time = rawData.time*1000;
        end

        data1.time              = repmat({timeVecFound}, 1, nTrialFound); % time bin labels
        data1.label             = cellstr(rawData.chs_name); % channel labels
        data1.trial             = squeeze(mat2cell(rawData.data, sum(indx_chan), nTimeFound, ones(1, nTrialFound)))'; % data
        data1.trialinfo.events         = rawData.events ; % trigger values per trial (as single row, thus transposed)
        data1.trialinfo.event_id = rawData.events_id
      
        % some trials contain NaN
        for i=1:length(data1.trial)
            trialnans(i)=sum(isnan(data1.trial{i}(32,:)));
        end
        if length(find(trialnans)) > 0
            error('Data has many trials with nan values - inspect.')
        end
        trialnans = []

        % --------------------------------------------------------------- %
        %% Re-sample to consistent time bins:

        % Limit new time vector to boundaries of data available:
        fprintf('*** Subject %02d: Resample to new time bins ***\n', iSub);

        timeVecNew     = timeVec_standard(timeVec_standard >= rawData.time(1) & timeVec_standard <= rawData.time(end));

        cfg                     = [];
        cfg.time                = repmat({timeVecNew}, 1, nTrialFound); % timeVecNew;
        cfg.demean              = 'no';
        cfg.detrend             = 'no';
        data3                   = ft_resampledata(cfg, data1);

        % --------------------------------------------------------------- %
        %% Epoch data to time window of interest:

        fprintf('*** Subject %02d: Select data in time window of %03d - +%03d ms***\n', ...
            iSub, timeWindow(1), timeWindow(end));
        cfg                     = [];
        cfg.latency             = timeWindow;
        cfg.avgovertime         = 'no';
        cfg.nanmean             = 'yes';
        data4                   = ft_selectdata(cfg, data3);

        %% add NaN for missing data to keep the same structure across teams

        if rawData.time(1)>-199 || rawData.time(end)<599
            indx_missing = ismember(timeVec_standard, data4.time{1});
            count = find(indx_missing);
            nan_start = nan(1,count(1)-1);
            nan_end = nan(1,length(timeVec_standard) - count(end));

            new_time = [nan_start, data4.time{1}, nan_end];

            for p = 1:length(data4.trial)
                data4.time(p) = {timeVec_standard};
                nan_start = nan(length(data4.label),count(1)-1);
                nan_end = nan(length(data4.label),length(timeVec_standard) - count(end));
                data4.trial(p) = {[nan_start, data4.trial{p}, nan_end]};
            end
        end

        %% Missing channels and channel order
        [indx_mchan pl_mchan] = ismember(eegChanVec,data4.label);

        chan_full = cell(1,length(eegChanVec));
        chan_full(indx_mchan) = data4.label(pl_mchan(find(pl_mchan))); % include labels of existing channels

        for p = 1:length(data4.trial)% re-order trials according to eegChanVec
            copy_data4 = data4;
            copy_data4.trial{p} = copy_data4.trial{p}(pl_mchan(find(pl_mchan)),:); %re-order time series data based on a standard channel order
            trial_templ = nan(length(eegChanVec),length(data4.time{p}));
            trial_templ(indx_mchan,:) = copy_data4.trial{p}; % include re-ordered data and NaN are kept for missing channels
            data4.trial(p) = {trial_templ};
        end

        data4.label = eegChanVec;
        % Store time info for a report txt file
        time =data4.time{1,1};

        % --------------------------------------------------------------- %
        %% Save chan x time matrix in teams x subjects cell:

        subID = str2double(extract( rawDataFiles(iSub).name,digitsPattern));%str2double(cell2mat(extractBetween(rawData(iSub).subID, 5, 6)));
        fprintf('*** Subject %02d: Save under subject ID %02d ***\n', iSub, subID);

        % Save in cell:
        alldatstand{1,subID} = data4;
        alldatstand{2,subID} = ['Subj-',num2str(subID)];


        fprintf('*** Subject %02d: FINISHED ***\n', iSub);
        clear data1 data3 data4   timeIdx cfg timeVecNew timeVecFound  nTimeFound nTrialFound rawData

    end % end iSub
    fprintf('*** TEAM %s: FINISHED  ***\n', teamList{iTeam});

    %save
    save([dirs.saveDirstand,'standart_',extractBefore(teamList{iTeam},'_')], 'alldatstand','-v7.3')

    %create a report
%     fileID = fopen([dirs.saveDirstand, 'standartization_report.txt'],'a+');
%     fprintf(fileID,'\n %s',datestr(datetime), ...
%         ['Processed team: ', teamList{iTeam}], ['Time window: ', num2str(time(1)),' to ', num2str(time(end))],...
%         ['Number of channels: ', num2str(sum(indx_chan))]);
%     fclose(fileID);

    clear  rawData alldatstand data4 nChanFound alldatavg
end % end iTeam


% END OF FILE.