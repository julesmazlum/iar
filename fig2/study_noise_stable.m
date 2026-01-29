function study_noise_stable
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));
    
    % Paramètres VKF standards
    lambda = 0.1;
    v0 = 0.1;
    sigma_model = 0.1; % Ce que le modèle croit être le bruit
    
    total_trials = 200;
    
    % Niveaux de bruit à tester (écart-type pour Linear, Probabilité pour Binary)
    noise_tags = {'Low Noise', 'Medium Noise', 'High Noise'};
    lin_noises = [0.02, 0.15, 0.6];   % Écart-type du bruit
    bin_probs  = [0.95, 0.75, 0.55]; % Plus on est proche de 0.5, plus c'est "bruité"

    for i = 1:3
        % 1. Génération des données stables (pas de sauts)
        % Linear : Toujours 0
        % Binary : Toujours la même probabilité
        [y_l, x_l] = generate_stable_lin(lin_noises(i), total_trials);
        [y_b, x_b] = generate_stable_bin(bin_probs(i), total_trials);

        % 2. Calcul VKF
        [m_l, k_l, v_l] = vkf_lin(y_l, lambda, v0, sigma_model);
        [m_b, k_b, v_b] = vkf_bin(y_b, lambda, v0, sigma_model);
        m_b_prob = 1./(1+exp(-m_b));

        % 3. Regroupement
        x_truth = [x_l, x_b];
        y_obs   = [y_l, y_b];
        vol     = [v_l, v_b];
        lr      = [k_l, k_b];
        preds   = [m_l, m_b_prob];

        % 4. Tracé (Layout original)
        plot_stable_noise(x_truth, y_obs, vol, lr, preds, noise_tags{i});
    end
end

function plot_stable_noise(x, y, v, lr, m, tag)
    fpos = [0.2 0.1 .55 .75];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Name', ['Stability Study: ' tag], 'Color', 'w', 'NumberTitle', 'off');
    set(gcf, 'units', 'normalized', 'position', fpos);
    
    nr = 3; nc = 2;

    for j = 1:2 % Colonnes
        sub_plts = (j == 1) * [1 3 5] + (j == 2) * [2 4 6];
        
        if j == 1
            yl = [0 0.2; 0.2 0.8; -1.5 1.5]; % Axes Linear
            title_s = ['Linear (' tag ')'];
        else
            yl = [0.05 0.15; 0.3 0.6; -0.1 1.1]; % Axes Binary
            title_s = ['Binary (' tag ')'];
        end
        
        % sim_A_plot pour l'esthétique originale
        h = sim_A_plot(nr, nc, sub_plts, x(:,j), y(:,j), v(:,j), lr(:,j), m(:,j), yl);
        
        for row = 1:3
            axes(h(row));
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        text(.5, yst, title_s, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end
end

% --- GÉNÉRATEURS DE DONNÉES STABLES ---

function [o, x] = generate_stable_lin(noise_std, total)
    x = zeros(total, 1); % La vérité est une ligne plate à 0
    o = x + noise_std * randn(total, 1); % On ajoute le bruit
end

function [o, x] = generate_stable_bin(p, total)
    % p = 0.95 (très clair, peu de bruit)
    % p = 0.55 (très bruité, presque 50/50)
    x = p * ones(total, 1);
    o = zeros(total, 1);
    o(rand(total, 1) < p) = 1;
end