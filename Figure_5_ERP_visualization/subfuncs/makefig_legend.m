function makefig_legend(cfg, icond, plot_hand)

for ilevel = 1:2
    
    cond_value = cfg.conditions{icond, ilevel}{2};
    
    if isnumeric(cond_value)
        condstr{ilevel} = sprintf('%s: %d', ...
            cfg.conditions{icond, ilevel}{1}, cond_value);
    elseif ischar(cond_value)
        condstr{ilevel} = sprintf('%s: %s', ...
            cfg.conditions{icond, ilevel}{1}, cond_value);
    end
    
end
legend(plot_hand, condstr, 'Interpreter', 'none', 'location', 'best')
legend('boxoff')