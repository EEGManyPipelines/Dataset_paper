# Code used to curate EEGManyPipelines data and produce plots for the Data Descriptor paper

EEGManyPipelines is a many-analyst study aiming to examine how differences in electrophysiology (EEG) data analysis may contribute to differences in the results. More about the project can be found at Trübutschek et al. (2024) "EEGManyPipelines: A Large-scale, Grassroots Multi-analyst Study of Electroencephalography Analysis Practices in the Wild" (https://doi.org/10.1162/jocn_a_02087)

## Folder structure
The folders contain R code used to generate plots for the Data Descriptor paper and MATLAB code used to curate the EEG time-series data for the analyses reported in the manuscript presenting the main findings of the project. A more detailed description of the dataset is provided in our Data Descriptor paper (link to be added once the paper is published online).

To facilitate data analysis across multiple teams, we curated the epoched EEG data (which was already transformed into .mat files) into a common format, matching the data files in terms of their sampling rate (250 Hz), epoch length (from -200 to 600 ms relative to image onset), and number and order of channels.

In case a team submitted shorter epochs or fewer channels than our defined standard, we filled the missing time points and channels with NaN values. 

All curated processed EEG data files are then stored as a single .mat file per team in the typical FieldTrip structure format. Files contain the following fields: a time vector for every epoch, channel labels, epoched EEG data, sampling frequency, configuration structure, the order of dimensions, and trial info.

## Dataset availability
The EEGManyPipelines dataset is available through the brainlife.io platform: https://brainlife.io/project/6863bf5c1521e536327bfea717. Everyone can access and download the data after registering on brainlife.io platform and agreeing to the brainlife.io Acceptable Use Policy and Privacy Policy. 

The data is available under the Creative Commons Attribution (CC-BY 4.0) license, which permits unrestricted use, distribution, and reproduction in any medium, provided the original work is properly cited.
The data can be downloaded through the web interface or by using a brainlife CLI. 


## Funding
The EEGManyPipelines project is supported by grants from German Research Foundation (DFG; BU 2400/11-1) to Niko A. Busch, by the DFG priority program "META-REP: A Meta-scientific Programme to Analyse and Optimise Replicability in the Behavioural, Social, and Cognitive Sciences"  to Niko A. Busch and Elena Cesnaite, and Riksbankens Jubileumsfond (grant number: P21-0384) to Gustav Nilsonne, together with Mikkel C. Vinding and Niko A. Busch

## Website
EEGManyPipelines website: https://eegmanypipelines.github.io/
