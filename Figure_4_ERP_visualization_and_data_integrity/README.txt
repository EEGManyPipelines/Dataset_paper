% This code reproduces Figure 4 from the EEGManyPipelines data descriptor
% paper: https://github.com/EEGManyPipelines
%
% The analysis presented here was conducted solely as a sanity check for
% the project steering committee, to confirm that expected effects in this
% type of paradigm can be qualitatively reproduced.
%
% The analysis pipeline is intentionally minimal: artifact rejection and
% correction were performed only at a bare minimum, and several steps
% typical in full analyses (e.g., more extensive preprocessing, advanced
% statistical procedures) were omitted. As such, this pipeline does not
% reflect the typical procedures of the committee members, nor should it be
% considered the optimal approach recommended by the EEGManyPipelines
% project.
%
% The results shown here, as obtained with this specific pipeline, are not
% intended for scientific inference and should not be interpreted as
% "ground truth" or as the "desired outcome" of the analysis.
%
% You can run the final script visualize_erp_results.m to reproduce Figure 5
% without going through the preceding processing steps, using the 
% grandaverage.mat file provided here. Note: you still need your own local
% instance of the EEGLAB toolbox.
%
% 2025-08-13, Niko Busch.

