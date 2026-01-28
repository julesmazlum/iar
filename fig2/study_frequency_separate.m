function study_frequency_separate
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres originaux
    lambda = 0.1;
    v0 = 0.1;
    sigma = 0.1;

    % Définition des fréquences pour la zone "active" (40 à 160)
    freq_names = {'Frequent', 'Normal', 'Infrequent'};
    block_lengths = [10, 20, 60]; % 60 pour Infrequent = 2 gros blocs dans la zone active
    total_trials = 200;

    for i = 1:3
        n = block_lengths(i);
        
        % 1. Génération des données avec la structure [Stable | Variable | Stable]
        [y_l, x_l] = generate_lin_freq_structured(n, total_trials);
        [y_b, x_b] = generate_bin_freq_structured(n, total_trials);

        % 2. Calcul VKF
        [m_l, k_l, v_l] = vkf_lin(y_l, lambda, v0, sigma);
        [m_b, k_b, v_b] = vkf_bin(y_b, lambda, v0, sigma);
        m_b_prob = 1./(1+exp(-m_b));

        % 3. Regroupement
        x_truth = [x_l, x_b];
        y_obs   = [y_l, y_b];
        vol     = [v_l, v_b];
        lr      = [k_l, k_b];
        preds   = [m_l, m_b_prob];

        % 4. Tracé
        plot_single_frequency(x_truth, y_obs, vol, lr, preds, freq_names{i}, n);
    end
end

function plot_single_frequency(x, y, v, lr, m, tag, n_val)
    fpos = [0.2 0.1 .55 .75];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Name', ['Frequency: ' tag ' (Zone 40-160)'], 'Color', 'w', 'NumberTitle', 'off');
    set(gcf, 'units', 'normalized', 'position', fpos);
    
    nr = 3; nc = 2;
    for j = 1:2
        sub_plts = (j == 1) * [1 3 5] + (j == 2) * [2 4 6];
        if j == 1
            yl = [0 0.6; 0.5 0.95; -1.9 1.9]; 
            title_s = ['Linear (' tag ')'];
        else
            yl = [0.05 0.2; 0.3 0.65; -0.1 1.1]; 
            title_s = ['Binary (' tag ')'];
        end
        
        h = sim_A_plot(nr, nc, sub_plts, x(:,j), y(:,j), v(:,j), lr(:,j), m(:,j), yl);
        for row = 1:3
            axes(h(row));
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        text(.5, yst, title_s, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end
end

% --- GÉNÉRATEURS DE DONNÉES STRUCTURÉS (40 - 160) ---

function [o, x] = generate_lin_freq_structured(n, total)
    x = ones(40, 1); % Stable initial (+1)
    
    % Zone variable (40 à 160 = 120 essais)
    zone_len = 120;
    nb_blocks = ceil(zone_len / n);
    x_zone = [];
    val = -1; % On commence par un switch à l'essai 40
    for i = 1:nb_blocks
        x_zone = [x_zone; val * ones(n, 1)];
        val = val * -1;
    end
    x = [x; x_zone(1:zone_len)];
    
    % Stable final (160 à 200)
    final_val = x(end);
    x = [x; final_val * ones(total - length(x), 1)];
    
    x = x(1:total);
    o = x + 0.1*randn(total, 1);
end

function [o, x] = generate_bin_freq_structured(n, total)
    p_high = 0.8; p_low = 0.2;
    x = p_high * ones(40, 1); % Stable initial
    
    % Zone variable (40 à 160)
    zone_len = 120;
    nb_blocks = ceil(zone_len / n);
    x_zone = [];
    prob = p_low; % Switch à l'essai 40
    for i = 1:nb_blocks
        x_zone = [x_zone; prob * ones(n, 1)];
        if prob == p_high, prob = p_low; else, prob = p_high; end
    end
    x = [x; x_zone(1:zone_len)];
    
    % Stable final
    final_p = x(end);
    x = [x; final_p * ones(total - length(x), 1)];
    x = x(1:total);
    
    % Génération des observations binaires
    o = zeros(total, 1);
    for t = 1:total
        if rand < x(t), o(t) = 1; end
    end
end