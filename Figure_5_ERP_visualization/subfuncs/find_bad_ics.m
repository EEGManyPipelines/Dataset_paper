function [badics] = find_bad_ics(EEG, eog_chans, corrthreshold)
% function [badics] = find_bad_ics(EEG, eog_chans, corrthreshold)
% This function automatically determines "bad" independent components.
% "Bad" ist defined as a component that correlates strongly with any of the
% EOG channels.
% 
% Inputs:
% EEG: eeglab dataset.
% eog_chans: indices of channels representingeog channels.
% corrthreshold: ICs are defined as bad if their corrlation with eog_chans
% exceeds this threshold.

% Recompute ICA timecourses
clear EEG.icaact;
EEG = eeg_checkset(EEG);


% Loop over ICs, compute their correlation with the EOG channels and test
% if the correlation exceeds the threshold.
for ichan = 1:length(eog_chans)
    
    eeg = EEG.data(eog_chans(ichan),:);
    
    for icomp = 1:size(EEG.icaact,1)
        
        ic = EEG.icaact(icomp,:);
        
        corr_tmp = corrcoef(ic, eeg);
        corr_eeg_ic(icomp,ichan) = corr_tmp(1,2);
        
    end
    
    badics{ichan} = find(abs(corr_eeg_ic(:,ichan)) >= corrthreshold)';
    badics_corr{ichan} = corr_eeg_ic(badics{ichan},ichan);
end

% Print result to command line.
fprintf('Found %d bad ICs.\n', length(unique([badics{:}])))
for ichan = 1:length(eog_chans)
    for ibad = 1:length(badics{ichan})
        fprintf('EEG chan %d: IC %d. r = %2.2f.\n', ...
            eog_chans(ichan), badics{ichan}(ibad), badics_corr{ichan}(ibad))
    end
end

% Return a list with the bad ICs.
badics = unique([badics{:}]);