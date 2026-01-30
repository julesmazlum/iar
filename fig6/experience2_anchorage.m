function experience2_anchorage()
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));
    
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres de la simulation
    n1 = 150; % Longue phase d'ancrage pour saturer le modèle
    n2 = 50;  % Rupture brutale
    ntrials = n1 + n2;
    
    p1 = 0.95; % Quasi-certitude
    p2 = 0.05; % Inversion totale
    
    % 1. Génération des données
    o = [rand(n1, 1) < p1; rand(n2, 1) < p2];
    o = double(o);
    
    % État caché x en espace latent (logit)
    % logit(p) = log(p/(1-p))
    x1 = log(p1/(1-p1)); 
    x2 = log(p2/(1-p2));
    x = [ones(n1, 1)*x1; ones(n2, 1)*x2];

    % 2. Paramètres des modèles (similaires à la Fig 6)
    lambda = 0.1; v0 = 1.0; omega_vkf = 0.1; % v0 un peu plus haut pour l'ancrage
    nu = 0.5; kappa = 1; omega_hgf = -3;

    % 3. Exécution du VKF
    [m_vkf, k_vkf, v_vkf] = vkf_bin(o, lambda, v0, omega_vkf);
    
    % 4. Exécution du HGF
    [~, ~, mu2, mu3, sigma2] = hgf_bin(o, nu, kappa, omega_hgf);
    
    val_hgf = mu2(1:end-1);
    vol_hgf = mu3(1:end-1);
    lr_hgf  = sigma2(2:end);

    % 5. Affichage
    fig_plot_exp2(x, o, m_vkf, v_vkf, k_vkf, val_hgf, vol_hgf, lr_hgf, n1);
end

function fig_plot_exp2(x,y,val1,vol1,lr1,val2,vol2,lr2, switch_point)
    nr = 3; nc = 2;
    fpos0 = [0.2, 0.08, 0.55, 0.7];
    
    figure('Units','normalized','Position',fpos0,'Name','Expérience 2 : Choc de l''ancrage');

    % Limites d'axes adaptées à l'espace latent élargi
    yl = [0 2.5;  % Volatilité
          0 1.0;  % Learning Rate
         -4 4];   % Predictions (Espace latent)

    % --- Colonne VKF ---
    hl = sim_C_plot(nr, nc, [1 3 5], x, y, vol1, lr1, val1, yl);
    title(hl(1), 'VKF (Réactivité post-ancrage)', 'FontSize', 12, 'FontWeight', 'bold');
    line([switch_point switch_point], yl(3,:), 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'Parent', hl(3));

    % --- Colonne HGF ---
    hr = sim_C_plot(nr, nc, [2 4 6], x, y, vol2, lr2, val2, yl);
    title(hr(1), 'HGF (Inertie du sigmoïde)', 'FontSize', 12, 'FontWeight', 'bold');
    line([switch_point switch_point], yl(3,:), 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'Parent', hr(3));
    
    % Annotation
    annotation('textbox', [0.35, 0.01, 0.3, 0.04], 'String', ...
        ['Ancrage à p=0.95 puis chute à p=0.05 à l''essai ', num2str(switch_point)], ...
        'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end