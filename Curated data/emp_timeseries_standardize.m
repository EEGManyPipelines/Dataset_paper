% The code uses the processed epoched EEG time series data submitted by teams in
% varying file formats (that were transformed into a .mat file) and standardizes it by applying
% the same window length, number of channels, and order of channels.
% Out of 90 teams that used EEGLAB, we had to skip team indices 
% [15,21,24,65,69,74,77,86]due to the following reasons:
% 15 - problem with resampling (interpolation problem), 
% 21,24,69,89 - could not load the data, 
% 65,74,86 - time information is missing, 
% 77 - no channel labels.

% Prepared in 27.09.2024 by EEGManyPipelines Steering Committee members
% Elena Cesnaite, Johannes Algermissen, Andrea Vitale
clear all, close all
% ----------------------------------------------------------------------- %
%% Set up directories:
dirs = [];
dirs.root       = 'C:\Users\ecesnait\Desktop\EEGManyPipelines\git\EEGManyPipes org\Main_Paper\';
dirs.scripts    = fullfile(dirs.root, 'johannes\timeseries');
dirs.data       = fullfile('M:\EMP\EEGManyPipelines\EMP time series exp\EEGLAB all teams'); % processed EEG data as submitted by analyst teams
dirs.saveDirstand = 'Z:\aebuschgold\ecesnait\EMP\EMP time series exp\Standardized\' % directory where the standardized data will be stored

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

% Expected number subjects:
nSub            = 33;

% Collect IDs of teams that did not epoch data
teamID_not_epoched = char()

% ----------------------------------------------------------------------- %
%% Detect input data, set settings:

% Detect all mat files:
selPattern  = '*.mat';
fprintf('*** Search for files with pattern %s ... ***\n', selPattern);
tmp         = dir(fullfile(dirs.data, selPattern));
teamList    = {tmp.name};
nTeam       = length(teamList);
fprintf('*** Found %d files:\n%s ***\n', nTeam, strjoin(teamList, ', '));

% ----------------------------------------------------------------------- %
%% Loop over teams:

for iTeam = 1:nTeam 
    if ismember(iTeam,[1,15,21,24,65,69,74,77,86]) % skip temporarily. Explanation above.
        continue
    end

    alldatstand = cell(1,nSub);

    if endsWith(teamList{iTeam}, '_2.mat')
        continue
    end

    % Load data:
    fprintf('*** ========================================================== ***\n');
    fprintf('*** TEAM %s: Start loading data ...  ***\n', teamList{iTeam});
    rawData         = load(fullfile(dirs.data, teamList{iTeam}));
    rawData         = rawData.data;
    fprintf('*** ... finished :-) ***\n');

    nSubFound       = size(rawData, 2);
    fprintf('*** Team %s: Found data from %02d subjects ***\n', teamList{iTeam}, nSubFound);

    % If data is not epoched - skip it.
    if numel(size(rawData(1).EEGts)) < 3 %check how many dimensions EEGts has. if it's conitnuous data: skip it
        fprintf('*** Team %s: the EEG data is not epoched', teamList{iTeam});
        teamID_not_epoched = [teamID_not_epoched,', ',teamList{iTeam}];
        clear rawData
        continue
    end
end

    % A special case
    if isequal(teamList{iTeam},'d9a070789fe1b133.mat') % nested channel label structures
        for i = 1:33
            rawData(i).chan = rawData(i).chan{1,1};
        end
    end

    % Loop over found subjects:
    for iSub = 1:nSubFound %
        fprintf('*** --------------------------------------------- ***\n');
        fprintf('*** Subject %02d: START ***\n', iSub);

        % Extract data dimensions:
        nChanFound = []
        nChanFound          = size(rawData(iSub).EEGts, 1);
        nTimeFound          = size(rawData(iSub).EEGts, 2);
        nTrialFound         = size(rawData(iSub).EEGts, 3);
        fprintf('*** Subject %02d: Found data from %d channels, %d time points, %d trials ***\n', ...
            iSub, nChanFound, nTimeFound, nTrialFound);

        if isempty(rawData(iSub).EEGts)
            fprintf('*** Subject %02d: Data is empty, skip subject ***\n', iSub);
            continue
        end

        %% Keep only the selected channels
        indx_chan = [];
        if isequal(teamList{iTeam}, 'f5e788cb73eec086.mat')
            rawData(iSub).chan = {rawData(iSub).chan.labels};
        end
        indx_chan = ismember(rawData(iSub).chan, eegChanVec);
        rawData(iSub).chan = rawData(iSub).chan(indx_chan);

        if size(rawData(iSub).EEGts,1) <=74 % first dimention should be channels
            rawData(iSub).EEGts = rawData(iSub).EEGts(indx_chan,:,:);
        else
            error('Inspect dimentions')
        end

        % --------------------------------------------------------------- %
        %% Create Fieldtrip structure:
        % Check if data exists (or subject excluded), if not, then skip:

        fprintf('*** Subject %02d: Cast into Fieldtrip structure ***\n', iSub);
        data1                   = []; % initialize
        data1.dimord            = 'chan_time'; % dimension order for each trial
        timeVecFound            = rawData(iSub).time; % extract time bin labels
        if (timeVecFound(end) - timeVecFound(1)) < 10 % if time is saved in seconds
            timeVecFound = timeVecFound * 1000
            rawData(iSub).time = rawData(iSub).time*1000;% convert from sec to ms
        end
        data1.time              = repmat({timeVecFound}, 1, nTrialFound); % time bin labels
        data1.label             = rawData(iSub).chan; % channel labels
        data1.trial             = squeeze(mat2cell(rawData(iSub).EEGts, sum(indx_chan), nTimeFound, ones(1, nTrialFound)))'; % data

        % --------------------------------------------------------------- %
        %% Re-sample to consistent time bins:

        % Limit new time vector to boundaries of data available:
        fprintf('*** Subject %02d: Resample to new time bins ***\n', iSub);

        timeVecNew     = timeVec_standard(timeVec_standard >= rawData(iSub).time(1) & timeVec_standard <= rawData(iSub).time(end));

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
        data4 = []
        data4                   = ft_selectdata(cfg, data3);

        %% add NaN for missing data to keep the same structure across teams

        if rawData(iSub).time(1)>-199 || rawData(iSub).time(end)<599
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
        chan_full(indx_mchan)=data4.label(pl_mchan(find(pl_mchan))); % include labels of existing channels
        for p = 1:length(data4.trial)
            copy_data4 = data4;
            copy_data4.trial{p} = copy_data4.trial{p}(pl_mchan(find(pl_mchan)),:);%re-order time series data based on a standard channel order
            trial_templ = nan(length(eegChanVec),length(data4.time{p}));
            trial_templ(indx_mchan,:) = copy_data4.trial{p}; % include re-ordered data and NaN are kept for missing channels
            data4.trial(p) = {trial_templ};
        end
        data4.label = eegChanVec;
        % Store time info for a report txt file
        time =data4.time{1,1};
        data4.trialinfo   = rawData(iSub).epoch;
        % --------------------------------------------------------------- %
        %% Save chan x time matrix in teams x subjects cell:

        subID = str2double(extract(rawData(iSub).subID,digitsPattern));%str2double(cell2mat(extractBetween(rawData(iSub).subID, 5, 6)));
        fprintf('*** Subject %02d: Save under subject ID %02d ***\n', iSub, subID);

        % Save in cell:
        alldatstand{1,subID} = data4;
        alldatstand{2,subID} = ['Subj-',num2str(subID)];

        fprintf('*** Subject %02d: FINISHED ***\n', iSub);
        clear data1 data3 timeIdx cfg timeVecNew timeVecFound  nTimeFound nTrialFound

    end % end iSub
    fprintf('*** TEAM %s: FINISHED  ***\n', teamList{iTeam});

    %% A special case - when a single team has more than 1 file -combine them and skip the  second file
    if endsWith(teamList{iTeam}, '_1.mat')
        clear rawData data4
        rawData         = load(fullfile(dirs.data, [extractBefore(teamList{iTeam}, '_1'),'_2.mat']));
        rawData         = rawData.data;
        nSubFound       = sum(~cellfun(@isempty,{rawData.subID}));
        indx_sub = find(~cellfun(@isempty,{rawData.subID}));

        % Loop over found subjects:
        for iSub = 1:nSubFound % iSub = 1;
            iSub = indx_sub(iSub)
            fprintf('*** --------------------------------------------- ***\n');
            fprintf('*** Subject %02d: START ***\n', iSub);

            % Extract data dimensions:
            nChanFound = []
            nChanFound          = size(rawData(iSub).EEGts, 1);
            nTimeFound          = size(rawData(iSub).EEGts, 2);
            nTrialFound         = size(rawData(iSub).EEGts, 3);
            fprintf('*** Subject %02d: Found data from %d channels, %d time points, %d trials ***\n', ...
                iSub, nChanFound, nTimeFound, nTrialFound);

            %% Keep only the selected channels
            indx_chan = [];
            if isequal(teamList{iTeam}, 'f5e788cb73eec086.mat')
                rawData(iSub).chan = {rawData(iSub).chan.labels};
            end
            indx_chan = ismember(rawData(iSub).chan, eegChanVec);
            rawData(iSub).chan = rawData(iSub).chan(indx_chan);

            if size(rawData(iSub).EEGts,1) <=74 % first dimention should be channels
                rawData(iSub).EEGts = rawData(iSub).EEGts(indx_chan,:,:);
            else
                error('Inspect dimentions')
            end
            % --------------------------------------------------------------- %
            %% Create Fieldtrip structure:
            % Check if data exists (or subject excluded), if not, then skip:
            if isempty(rawData(iSub).EEGts)
                fprintf('*** Subject %02d: Data is empty, skip subject ***\n', iSub);
                continue
            else
                fprintf('*** Subject %02d: Cast into Fieldtrip structure ***\n', iSub);
                data1                   = []; % initialize
                data1.dimord            = 'chan_time'; % dimension order for each trial
                timeVecFound            = rawData(iSub).time; % extract time bin labels
                if (timeVecFound(end) - timeVecFound(1)) < 10; timeVecFound = timeVecFound * 1000; end % convert from sec to ms
                data1.time              = repmat({timeVecFound}, 1, nTrialFound); % time bin labels
                data1.label             = rawData(iSub).chan; % channel labels
                data1.trial             = squeeze(mat2cell(rawData(iSub).EEGts, sum(indx_chan), nTimeFound, ones(1, nTrialFound)))'; % data

                data1.trialinfo         = rawData(iSub).epoch; % trigger values per trial (as single row, thus transposed)                end
                % --------------------------------------------------------------- %
                %% Re-sample to consistent time bins:

                % Limit new time vector to boundaries of data available:
                fprintf('*** Subject %02d: Resample to new time bins ***\n', iSub);
                timeVecNew     = timeVec_standard(timeVec_standard >= rawData(iSub).time(1) & timeVec_standard <= rawData(iSub).time(end));

                cfg                     = [];
                cfg.time                = repmat({timeVecNew}, 1, nTrialFound); % timeVecNew;
                cfg.demean              = 'no';
                cfg.detrend             = 'no';
                data3                   = ft_resampledata(cfg, data1);
                % data3.time{1}

                % --------------------------------------------------------------- %
                %% Epoch data to time window of interest:

                fprintf('*** Subject %02d: Select data in time window of %03d - +%03d ms***\n', ...
                    iSub, timeWindow(1), timeWindow(end));
                cfg                     = [];
                cfg.latency             = timeWindow;
                cfg.avgovertime         = 'no';
                cfg.nanmean             = 'yes';
                data4 = []
                data4                   = ft_selectdata(cfg, data3);
                %------------------------------------------------------------- %
                %% add NaN for missing data to keep the same structure across teams

                if rawData(iSub).time(1)>-199 || rawData(iSub).time(end)<599
                    indx_missing = ismember(timeVec_standard, data4.time{1})
                    count = find(indx_missing)
                    nan_start = nan(1,count(1)-1)
                    nan_end = nan(1,length(timeVec_standard) - count(end))

                    new_time = [nan_start, data4.time{1}, nan_end]

                    for p = 1:length(data4.trial)
                        data4.time(p) = {timeVec_standard};
                        nan_start = nan(length(data4.label),count(1)-1);
                        nan_end = nan(length(data4.label),length(timeVec_standard) - count(end));
                        data4.trial(p) = {[nan_start, data4.trial{p}, nan_end]}
                    end
                end
                %% Missing channels and channel order
                [indx_mchan pl_mchan] = ismember(eegChanVec,data4.label);

                chan_full = cell(1,length(eegChanVec));
                chan_full(indx_mchan)=data4.label(pl_mchan(find(pl_mchan))); % include labels of existing channels
                for p = 1:length(data4.trial)
                    copy_data4 = data4;
                    copy_data4.trial{p} = copy_data4.trial{p}(pl_mchan(find(pl_mchan)),:);%re-order time series data based on a standard channel order
                    trial_templ = nan(length(eegChanVec),length(data4.time{p}));
                    trial_templ(indx_mchan,:) = copy_data4.trial{p}; % include re-ordered data and NaN are kept for missing channels
                    data4.trial(p) = {trial_templ};
                end
                data4.label = eegChanVec;
                % Store time info for a report txt file
                time =data4.time{1,1};
                data4.trialinfo   = rawData(iSub).epoch;

                % --------------------------------------------------------------- %
                subID = str2double(extract(rawData(iSub).subID,digitsPattern));%str2double(cell2mat(extractBetween(rawData(iSub).subID, 5, 6)));
                fprintf('*** Subject %02d: Save under subject ID %02d ***\n', iSub, subID);

                % Save in cell:
                alldatstand{1,subID} = data4;
                alldatstand{2,subID} = ['Subj-',num2str(subID)];

            end % if data is empty
            fprintf('*** Subject %02d: FINISHED ***\n', iSub);
            clear data1 data3 data5 data6 data7 timeIdx cfg timeVecNew timeVecFound  nTimeFound nTrialFound

        end % end iSub
        fprintf('*** TEAM %s: FINISHED  ***\n', teamList{iTeam});

    end

    %save
    save([dirs.saveDirstand,'standart_',extractBefore(teamList{iTeam},'.mat')], 'alldatstand','-v7.3')
   
    % %create a report
    % fileID = fopen([dirs.saveDirstand, 'standartization_report.txt'],'a+');
    % fprintf(fileID,'\n %s',datestr(datetime), ...
    %     ['Processed team: ', teamList{iTeam}], ['Time window: ', num2str(time(1)),' to ', num2str(time(end))],...
    %     ['Number of channels: ', num2str(sum(indx_chan))]);
    % fclose(fileID);

    clear  rawData alldatstand data4 nChanFound
end % end iTeam


% END OF FILE.