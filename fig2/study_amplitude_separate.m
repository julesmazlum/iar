function study_amplitude_separate
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres du modèle (fixes selon Fig 2)
    lambda = 0.1;
    v0 = 0.1;
    sigma = 0.1;

    % Définition des niveaux d'amplitude
    amp_names = {'Small', 'Normal', 'Large'};
    lin_amps  = [0.3, 1.0, 2.5];     % Amplitude du signal linéaire
    bin_probs = [0.6, 0.8, 0.98];   % Probabilité (0.5 = hasard, 1.0 = déterministe)

    % On boucle pour créer 3 figures
    for i = 1:3
        % 1. Génération des données spécifiques à cette amplitude
        [y_l, x_l] = generate_lin_data(lin_amps(i));
        [y_b, x_b] = generate_bin_data(bin_probs(i));

        % 2. Calcul du modèle VKF
        [m_l, k_l, v_l] = vkf_lin(y_l, lambda, v0, sigma);
        [m_b, k_b, v_b] = vkf_bin(y_b, lambda, v0, sigma);
        m_b_prob = 1./(1+exp(-m_b));

        % 3. Préparation des données pour le tracé
        % On regroupe [Linear, Binary]
        x_truth = [x_l, x_b];
        y_obs   = [y_l, y_b];
        vol     = [v_l, v_b];
        lr      = [k_l, k_b];
        preds   = [m_l, m_b_prob];

        % 4. Affichage de la figure pour cette amplitude
        plot_single_amplitude(x_truth, y_obs, vol, lr, preds, amp_names{i});
    end
end

function plot_single_amplitude(x, y, v, lr, m, title_tag)
    % Configuration du layout (identique au papier)
    fpos = [0.2 0.1 .55 .75];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Name', ['Amplitude: ' title_tag], 'Color', 'w', 'NumberTitle', 'off');
    set(gcf, 'units', 'normalized', 'position', fpos);
    
    nr = 3; nc = 2;

    for j = 1:2 % Colonne 1: Linear, Colonne 2: Binary
        sub_plts = (j == 1) * [1 3 5] + (j == 2) * [2 4 6];
        
        % /!\ IMPORTANT : On fixe les axes identiques sur les 3 figures 
        % pour permettre la comparaison visuelle de l'amplitude.
        if j == 1
            yl = [0 1.2; 0.4 1.0; -3.5 3.5]; % Axes Linear
            title_s = ['Linear (' title_tag ')'];
        else
            yl = [0 0.5; 0.3 0.8; -0.1 1.1]; % Axes Binary
            title_s = ['Binary (' title_tag ')'];
        end
        
        % sim_A_plot (fonction originale du papier pour le style)
        h = sim_A_plot(nr, nc, sub_plts, x(:,j), y(:,j), v(:,j), lr(:,j), m(:,j), yl);
        
        % On s'assure que les labels et couleurs respectent la figure 2
        for row = 1:3
            axes(h(row));
            % Les couleurs originales : Orange pour Vol/LR/Pred
            % La vérité terrain est gérée par sim_A_plot (ligne noire)
            
            % Ajout des lettres A-F
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        
        % Titre de la colonne
        text(.5, yst, title_s, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end
end

% --- GÉNÉRATEURS DE DONNÉES ---

function [o, x] = generate_lin_data(amp)
    p = [ones(1,2) -1 1 -1 1 -1 -ones(1,3)]; % Séquence de sauts
    n = 20; w = 0.01; % Bruit faible pour bien voir l'effet
    nb = length(p); N = nb*n; x = nan(N,1); o = nan(N,1);
    for i=1:nb
        ii = (i-1)*n + (1:n);
        x(ii) = p(i) * amp;
        o(ii) = x(ii) + sqrt(w)*randn(n,1);
    end
end

function [o, x] = generate_bin_data(p0)
    % p0 est la probabilité haute (ex: 0.98), 1-p0 la basse (0.02)
    p_seq = [p0 p0 (1-p0) p0 (1-p0) p0 (1-p0) (1-p0) (1-p0) (1-p0)];
    n = 20; nb = length(p_seq); N = nb*n; x = nan(N,1); o = zeros(N,1);
    t0 = 0;
    for i = 1:nb
        ii = t0 + (1:n);
        x(ii) = p_seq(i);
        ni = randperm(n);
        ni = ni(1: round(p_seq(i)*n));
        o(ii(ni)) = 1;
        t0 = t0 + n;
    end
end