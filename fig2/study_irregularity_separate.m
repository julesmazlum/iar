function study_irregularity_separate
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres originaux
    lambda = 0.1;
    v0 = 0.1;
    sigma = 0.1;
    total_trials = 220; % Un peu plus long pour accommoder les blocs variés

    % Définition des types d'irrégularité (longueurs de blocs)
    % On définit des séquences spécifiques pour que vous puissiez comparer
    types = {'Regular', 'Jittered', 'Highly Irregular'};
    
    % Blocs réguliers (Original)
    blocks{1} = repmat(20, 1, 11); 
    
    % Blocs légèrement variés (moyenne ~20)
    blocks{2} = [15, 25, 12, 28, 20, 18, 22, 30, 15, 35]; 
    
    % Blocs très irréguliers (mélange court/long)
    blocks{3} = [5, 60, 10, 45, 8, 50, 12, 30]; 

    for i = 1:3
        current_blocks = blocks{i};
        
        % 1. Génération des données
        [y_l, x_l, cp_l] = generate_lin_irreg(current_blocks, total_trials);
        [y_b, x_b, cp_b] = generate_bin_irreg(current_blocks, total_trials);

        % 2. Calcul VKF
        [m_l, k_l, v_l] = vkf_lin(y_l, lambda, v0, sigma);
        [m_b, k_b, v_b] = vkf_bin(y_b, lambda, v0, sigma);
        m_b_prob = 1./(1+exp(-m_b));

        % 3. Tracé
        plot_single_irreg(x_l, x_b, y_l, y_b, v_l, v_b, k_l, k_b, m_l, m_b_prob, types{i});
    end
end

function plot_single_irreg(xl, xb, yl, yb, vl, vb, kl, kb, ml, mb, tag)
    fpos = [0.2 0.1 .55 .75];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Name', ['Irregularity: ' tag], 'Color', 'w', 'NumberTitle', 'off');
    set(gcf, 'units', 'normalized', 'position', fpos);
    
    % On regroupe pour sim_A_plot
    X = [xl, xb]; Y = [yl, yb]; V = [vl, vb]; LR = [kl, kb]; M = [ml, mb];
    nr = 3; nc = 2;

    for j = 1:2
        sub_plts = (j == 1) * [1 3 5] + (j == 2) * [2 4 6];
        if j == 1
            ylims = [0 0.6; 0.5 0.9; -1.9 1.9]; 
            title_s = ['Linear (' tag ')'];
        else
            ylims = [0.05 0.25; 0.3 0.65; -0.1 1.1]; 
            title_s = ['Binary (' tag ')'];
        end
        
        % sim_A_plot tracera automatiquement les lignes grises aux points de changement
        h = sim_A_plot(nr, nc, sub_plts, X(:,j), Y(:,j), V(:,j), LR(:,j), M(:,j), ylims);
        
        for row = 1:3
            axes(h(row));
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        text(.5, yst, title_s, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end
end

% --- GÉNÉRATEURS DE DONNÉES IRRÉGULIÈRES ---

function [o, x, cp] = generate_lin_irreg(blocks, total)
    x = [];
    val = 1;
    for i = 1:length(blocks)
        x = [x; val * ones(blocks(i), 1)];
        val = val * -1; % Inversion
    end
    x = x(1:total);
    o = x + 0.1*randn(total, 1);
    cp = find(diff(x) ~= 0); % Points de changement
end

function [o, x, cp] = generate_bin_irreg(blocks, total)
    x = [];
    o = [];
    p_high = 0.8; p_low = 0.2;
    prob = p_high;
    for i = 1:length(blocks)
        len = blocks(i);
        x = [x; prob * ones(len, 1)];
        
        o_block = zeros(len, 1);
        ni = randperm(len);
        ni = ni(1: round(prob*len));
        o_block(ni) = 1;
        o = [o; o_block];
        
        % Switch prob
        if prob == p_high, prob = p_low; else, prob = p_high; end
    end
    x = x(1:total);
    o = o(1:total);
    cp = find(diff(x) ~= 0);
end