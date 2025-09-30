
function makefig_formatplot(fig, icond)

xline(0, 'color', [0.8 0.8 0.8]);
yline(0, 'color', [0.8 0.8 0.8]);
xlabel('time (ms)')
ylabel('amplitude (µV)')
title({fig.cond_title{icond}, fig.stat_str})
xlim([fig.tplot]);

ylims = get(gca, 'Ylim');
fl = patch([fig.twin(icond,1) fig.twin(icond,2) fig.twin(icond,2) fig.twin(icond,1)],...
    [ylims(1)+0.1 ylims(1)+0.1 ylims(2) ylims(2)], ...
    'r', 'facecolor', [0.9 0.9 0.9], 'edgecolor', 'none');

% set(gca,'children',[ph fl]);
uistack(fl, 'bottom')

set(gca,'TickDir','out');