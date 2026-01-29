function study_noise_burst
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));
    
    % Paramètres du modèle VKF (Le modèle croit que sigma est fixe à 0.1)
    lambda = 0.1;
    v0 = 0.1;
    sigma_model = 0.1; 
    T = 200;

    % --- PRÉPARATION DES DONNÉES (Linear) ---
    x_lin = zeros(T, 1); % La vérité ne bouge JAMAIS (fixe à 0)
    y_lin = zeros(T, 1);
    
    % On crée un burst de bruit entre l'essai 75 et 125
    for t = 1:T
        if t >= 75 && t <= 125
            current_noise = 1.2; % BRUIT MASSIF
        else
            current_noise = 0.1; % Bruit normal
        end
        y_lin(t) = x_lin(t) + current_noise * randn;
    end

    % --- PRÉPARATION DES DONNÉES (Binary) ---
    x_bin = 0.5 * ones(T, 1); 
    y_bin = zeros(T, 1);
    for t = 1:T
        if t >= 75 && t <= 125
            % Zone de chaos : pile ou face pur (bruit maximum pour du binaire)
            y_bin(t) = double(rand > 0.5);
        else
            % Zone stable : on donne presque toujours 0
            y_bin(t) = double(rand > 0.95); 
            x_bin(t) = 0.05;
        end
    end

    % --- CALCULS VKF ---
    % On utilise bien les variables y_lin et y_bin définies plus haut
    [m_l, k_l, v_l] = vkf_lin(y_lin, lambda, v0, sigma_model);
    [m_b, k_b, v_b] = vkf_bin(y_bin, lambda, v0, sigma_model);

    % Regroupement pour l'affichage
    X = [x_lin, x_bin];
    Y = [y_lin, y_bin];
    V = [v_l, v_b];
    LR = [k_l, k_b];
    M = [m_l, 1./(1+exp(-m_b))];

    % --- TRACÉ ---
    plot_noise_study(X, V, LR, M, Y);
end

function plot_noise_study(x, v, lr, m, y)
    fpos0 = [0.2 0.0800 .55*1.0000 .7*0.8133];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Color','w','Name','Weakness Study: Noise Burst','NumberTitle','off');
    set(gcf,'units','normalized','position',fpos0);

    for j = 1:2
        sub_plts = (j==1)*[1 3 5] + (j==2)*[2 4 6];
        if j == 1
            yl = [0 1.5; 0.5 1.0; -2.5 2.5]; title_s = 'Linear (Noise Burst)';
        else
            yl = [0.05 0.3; 0.3 0.7; -0.1 1.1]; title_s = 'Binary (Chaos Zone)';
        end
        
        % Appel à sim_A_plot pour l'esthétique originale
        h = sim_A_plot(3, 2, sub_plts, x(:,j), y(:,j), v(:,j), lr(:,j), m(:,j), yl);
        
        for row = 1:3
            axes(h(row)); hold on;
            % On trace des lignes rouges en pointillés pour délimiter visuellement le burst de bruit
            ylimit = ylim;
            line([75 75], ylimit, 'Color', 'r', 'LineStyle', ':', 'LineWidth', 1.5);
            line([125 125], ylimit, 'Color', 'r', 'LineStyle', ':', 'LineWidth', 1.5);
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        text(.5, yst, title_s, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end
end