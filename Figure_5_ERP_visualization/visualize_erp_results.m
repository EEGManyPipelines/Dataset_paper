% This script reproduces Figure 5 from the EEGManyPipelines data descriptor paper:
% https://github.com/EEGManyPipelines
%
% See README.txt for additional comments.

%% Silently load EEGLAB once to load all necessary paths. 
% Then wipe all the unnessesary variables.
addpath('X:\aebusch\nbusch\projects\EEG-Many-Pipelines\toolboxes\eeglab2021.0\');
addpath('./subfuncs/')
eeglab nogui; clear; close all

%%
load('grandaverage.mat')

cfg.conditions = {
    {'scene_category', 'manmade'}, {'scene_category', 'natural'};
    {'old', 'new'}, {'old', 'old'};
    {'behavior', 'hit'}, {'behavior', 'miss'};
    {'subsequent_memory', 'subsequent_forgotten'}, {'subsequent_memory', 'subsequent_remembered'};
    };

%%
nconds = size(cfg.conditions,1);
nsubs  = length(grand.hit_rate);
alphabet = ('A':'Z').';
chars = num2cell(alphabet(1:nconds));
chars = chars.';
charlbl = strcat('(',chars,')');

fig.cond_title{1} = 'Scene category';
fig.cond_title{2} = 'Old/new effect';
fig.cond_title{3} = 'Remembered/forgotten';
fig.cond_title{4} = 'Subsequent memory effect';

fig.t = grand.times;
fig.chans{1, :} = [28 29 30]; %[25 27 29 64 62]
fig.chans{2, :} = [48 32 47 ];
fig.chans{3, :} = [12 48 49 19 32 56];
fig.chans{4, :} = [3 37 36 4 38 39];

fig.twin(1, :) = [100 200];
fig.twin(2, :) = [300 600];
fig.twin(3, :) = [500 800];
fig.twin(4, :) = [300 600];

for i = 1:nconds
    fig.xwin(i, :) = round(eeg_lat2point(fig.twin(i, :), 1, ...
        grand.srate, [fig.t(1) fig.t(end)], 1/1000)); % Convert time to sampling points
end

fig.tplot = [-200 800];

fig.cm_lines1 = brewermap(2, 'Pastel1');
fig.cm_lines2 = brewermap(nsubs, 'Blues');

close all
fighand = figure(1); set(fighand, 'color', 'w');

for icond = 1:nconds

    % .................................................................
    % Compute data for plotting
    % .................................................................
    plot_erp = mmean(grand.data(fig.chans{icond,:}, :, :, icond, :), [1, 3]);
    plot_erp = my_bslcorrect(plot_erp, 1, grand.times, [-500 0], 'sub');

    plot_topo = mmean(grand.data(1:70, fig.xwin(icond,1):fig.xwin(icond,2), :, icond, :), [2, 3]);
    plot_topo = plot_topo(:,2) - plot_topo(:,1);

    statdata = mmean(...
        grand.data(fig.chans{icond,:}, ...
        fig.xwin(icond,1):fig.xwin(icond,2), :, icond, :), [1 2]);

    [h,p,ci,stats] = ttest(statdata(:,1), statdata(:,2));
    fig.stat_str = sprintf('t(%d)=%2.2f; p=%0.3f', stats.df, stats.tstat, p);

    % .................................................................
    % Line plot
    % .................................................................
    erpax(icond) = sanesubplot(2, nconds, {1, icond}); hold all

    text(-0.1,1.1,charlbl{icond},'Units','normalized','FontSize',14, ...
        'FontWeight', 'Bold')

    plothand = plot(fig.t, plot_erp, 'linewidth', 2);
    makefig_formatplot(fig, icond)

    makefig_legend(cfg, icond, plothand)
    set(erpax(icond), 'colororder', fig.cm_lines1)

    % .................................................................
    % Topography/Scatter plot
    % .................................................................
    topoax(icond) = sanesubplot(2, nconds, {2, icond});
    makefig_topo(plot_topo, grand.chanlocs, [fig.chans{icond,:}])

end

rb=brewermap(64, '*RdBu');
for i = 1:nconds
    colormap(topoax(i), rb);
end

set(fighand,'units','normalized','position',[0.1,0.1,0.8,0.8])
set(fighand,'DefaultAxesFontName','Arial')
set(fighand,'DefaultTextFontName','Arial')

if ~exist('./figures'), mkdir('./figures'); end

out = fullfile('./figures','figure5');

if ~exist('./figures','dir'), mkdir figures; end
print(gcf, [out '.png'], '-dpng', '-r300');
disp('Done.')
