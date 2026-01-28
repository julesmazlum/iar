function study_amplitude
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres du modèle (fixes)
    lambda = 0.1;
    v0 = 0.1;
    sigma = 0.1;

    % Définition des 3 niveaux d'amplitude
    % Multiplicateurs pour Linear et Probabilités pour Binary
    amp_labels = {'Small', 'Normal', 'Large'};
    lin_amps = [0.3, 1.0, 2.5];     % Écart par rapport à 0
    bin_probs = [0.6, 0.8, 0.98];   % Probabilité de la récompense haute

    % Initialisation des structures de données
    % Format : [N_trials x N_amplitudes]
    vol_all = cell(1,2); lr_all = cell(1,2); val_all = cell(1,2);
    x_truth = cell(1,2); y_obs = cell(1,2);

    for i = 1:3
        % --- GÉNÉRATION ET CALCUL LINEAR ---
        [y_l, x_l] = generate_lin_data(lin_amps(i));
        [m_l, k_l, v_l] = vkf_lin(y_l, lambda, v0, sigma);
        
        x_truth{1}(:,i) = x_l;
        y_obs{1}(:,i) = y_l;
        vol_all{1}(:,i) = v_l;
        lr_all{1}(:,i) = k_l;
        val_all{1}(:,i) = m_l;

        % --- GÉNÉRATION ET CALCUL BINARY ---
        [y_b, x_b] = generate_bin_data(bin_probs(i));
        [m_b, k_b, v_b] = vkf_bin(y_b, lambda, v0, sigma);
        
        x_truth{2}(:,i) = x_b;
        y_obs{2}(:,i) = y_b;
        vol_all{2}(:,i) = v_b;
        lr_all{2}(:,i) = k_b;
        val_all{2}(:,i) = 1./(1+exp(-m_b));
    end

    % Tracé de la figure
    plot_amplitude_results(x_truth, y_obs, vol_all, lr_all, val_all, amp_labels);
end

function plot_amplitude_results(x_t, y_o, v, lr, m, labels)
    fpos = [0.2 0.08 .55 .8];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Name', 'Effect of Amplitude', 'Color', 'w');
    set(gcf, 'units', 'normalized', 'position', fpos);
    
    colors = [0 0.447 0.741; 0.85 0.325 0.098; 0.466 0.674 0.188]; % Bleu, Orange, Vert
    nr = 3; nc = 2;

    for j = 1:2 % 1:Linear, 2:Binary
        sub_plts = (j == 1) * [1 3 5] + (j == 2) * [2 4 6];
        % On ajuste les axes Y pour que la grande amplitude soit visible
        if j == 1, yl = [0 1.5; 0 1; -3 3]; title_s = 'Linear';
        else, yl = [0 .3; 0.3 0.8; -0.1 1.1]; title_s = 'Binary'; end
        
        % Utilisation de sim_A_plot pour garder le style original (lignes grises)
        h = sim_A_plot(nr, nc, sub_plts, x_t{j}(:,2), y_o{j}(:,2), v{j}(:,2), lr{j}(:,2), m{j}(:,2), yl);
        
        for row = 1:3
            axes(h(row)); hold on; cla;
            
            % 1. Lignes de changement
            cp = find(diff(x_t{j}(:,2)) ~= 0);
            for k=1:length(cp), line([cp(k) cp(k)], ylim, 'Color', [.9 .9 .9], 'HandleVisibility', 'off'); end
            
            % 2. Tracé des 3 amplitudes
            h_lines = [];
            for i = 1:3
                if row == 1 % Volatility
                    h_lines(i) = plot(v{j}(:,i), 'Color', colors(i,:), 'LineWidth', 1.5);
                    ylabel('Volatility');
                elseif row == 2 % Learning Rate
                    h_lines(i) = plot(lr{j}(:,i), 'Color', colors(i,:), 'LineWidth', 1.5);
                    ylabel('Learning rate');
                else % Predictions
                    % On trace la vérité terrain pointillée de la couleur correspondante
                    plot(x_t{j}(:,i), '--', 'Color', colors(i,:), 'LineWidth', 0.8, 'HandleVisibility', 'off');
                    h_lines(i) = plot(m{j}(:,i), 'Color', colors(i,:), 'LineWidth', 1.5);
                    ylabel('Predictions');
                end
            end
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        text(.5, yst, title_s, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end

    % Légende horizontale en bas
    lgd = legend(h_lines, labels, 'Orientation', 'horizontal');
    set(lgd, 'Position', [0.4, 0.02, 0.2, 0.03], 'Units', 'normalized');
end

% --- GÉNÉRATEURS DE DONNÉES SUR MESURE ---

function [o, x] = generate_lin_data(amp)
    % Structure de base de la figure 2 : [1, 1, -1, 1, -1, 1, -1, -1, -1, -1]
    p = [ones(1,2) -1 1 -1 1 -1 -ones(1,3)]; % Simplifié pour l'exemple
    n = 20; w = 0.01;
    nb = length(p); N = nb*n; x = nan(N,1); o = nan(N,1);
    for i=1:nb
        ii = (i-1)*n + (1:n);
        x(ii) = p(i) * amp; % Application de l'amplitude
        o(ii) = x(ii) + sqrt(w)*randn(n,1);
    end
end

function [o, x] = generate_bin_data(p0)
    % p0 est la probabilité haute (ex: 0.8), 1-p0 est la basse (0.2)
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