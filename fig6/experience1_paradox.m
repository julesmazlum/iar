function experience1_paradox()
    % Paramètres de simulation
    ntrials = 200;
    p_true = 0.5; % Hasard pur
    
    % 1. Génération des données : Signal stationnaire à 0.5
    % L'état caché x est à 0 car sigmoid(0) = 0.5
    x = zeros(ntrials, 1)'; 
    o = rand(ntrials, 1) < p_true; % Séquence binaire aléatoire
    o = double(o); % Conversion en double pour les calculs

    % 2. Paramètres des modèles (Valeurs standards pour comparaison)
    % On utilise des valeurs typiques pour ne pas biaiser le test
    
    % Paramètres VKF
    lambda = 0.1; 
    v0 = 0.1;
    omega_vkf = 0.1;
    
    % Paramètres HGF (ajustés pour être comparables)
    nu = 0.5;
    kappa = 1;
    omega_hgf = -3; 

    % 3. Exécution du VKF
    [m_vkf, k_vkf, v_vkf] = vkf_bin(o, lambda, v0, omega_vkf);
    
    % 4. Exécution du HGF
    % mu2: état latent, mu3: volatilité, sigma2: incertitude (utilisée pour LR)
    [~, ~, mu2, mu3, sigma2] = hgf_bin(o, nu, kappa, omega_hgf);
    
    % Ajustement des tailles pour le plotting (comme dans votre code ref)
    val_vkf = m_vkf;
    vol_vkf = v_vkf;
    lr_vkf  = k_vkf;
    
    val_hgf = mu2(1:end-1);
    vol_hgf = mu3(1:end-1);
    lr_hgf  = sigma2(2:end);

    % 5. Affichage
    % On réutilise votre fonction de plot pour garder la cohérence visuelle
    % Note : les limites d'axes (yl) peuvent être ajustées si besoin
    fig_plot_exp1(x, o, val_vkf, vol_vkf, lr_vkf, val_hgf, vol_hgf, lr_hgf);
end

% Version modifiée de votre fonction fig_plot pour l'expérience 1
function fig_plot_exp1(x,y,val1,vol1,lr1,val2,vol2,lr2)
    nr = 3; nc = 2;
    fpos0 = [0.2, 0.08, 0.55, 0.65];
    
    % Récupération des réglages par défaut (assurez-vous que getdefaults existe)
    fnt = 'Helvetica'; % Remplacer par getdefaults si besoin
    fst = 12;
    yst = 1.1;

    figure('Units','normalized','Position',fpos0,'Name','Expérience 1 : Paradoxe p=0.5');

    % Limites d'axes adaptées au hasard pur
    yl = [0 1.2;  % Volatilité
          0 1.0;  % Learning Rate
         -3 3];   % Predictions (Espace latent)

    % --- Colonne VKF ---
    % Utilise votre fonction sim_C_plot existante
    hl = sim_C_plot(nr, nc, [1 3 5], x, y, vol1, lr1, val1, yl);
    title(hl(1), 'VKF (Stable sous bruit)', 'FontSize', fst, 'FontWeight', 'bold');

    % --- Colonne HGF ---
    hr = sim_C_plot(nr, nc, [2 4 6], x, y, vol2, lr2, val2, yl);
    title(hr(1), 'HGF (Instabilité du gain)', 'FontSize', fst, 'FontWeight', 'bold');
    
    % Ajout d'une annotation pour expliquer le résultat
    annotation('textbox', [0.4, 0.01, 0.2, 0.04], 'String', ...
        'Séquence Aléatoire Stationnaire (p=0.5)', 'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end