function study_random_levels
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres originaux
    lambda = 0.1;
    v0 = 0.1;
    sigma = 0.1;

    % 1. Génération des données avec niveaux aléatoires
    [y_l, x_l] = generate_random_levels_lin;
    [y_b, x_b] = generate_random_levels_bin;

    % 2. Calcul VKF Linear
    [m_l, k_l, v_l] = vkf_lin(y_l, lambda, v0, sigma);
    val(:,1) = m_l;
    vol(:,1) = v_l;
    kal(:,1) = k_l;
    y_data(:,1) = y_l;
    x_truth(:,1) = x_l;

    % 3. Calcul VKF Binary
    [m_b, k_b, v_b] = vkf_bin(y_b, lambda, v0, sigma);
    val(:,2) = 1./(1+exp(-m_b)); % Transformation en probabilité
    vol(:,2) = v_b;
    kal(:,2) = k_b;
    y_data(:,2) = y_b;
    x_truth(:,2) = x_b;

    % 4. Tracé (Utilise exactement votre layout original)
    fig_plot(x_truth, vol, kal, val, y_data);
end

% --- FONCTIONS DE GÉNÉRATION DE NIVEAUX ALÉATOIRES ---

function [o, x] = generate_random_levels_lin
    n = 20; % Longueur des blocs
    nb = 10; % Nombre de blocs
    total = n * nb;
    x = zeros(total, 1);
    
    rng('shuffle'); % Pour avoir des résultats différents à chaque run
    for i = 1:nb
        ii = (i-1)*n + (1:n);
        % On tire une valeur aléatoire entre -2 et 2
        rand_val = -2 + (2 - (-2)) * rand; 
        x(ii) = rand_val;
    end
    w = 0.01;
    o = x + sqrt(w)*randn(total, 1);
end

function [o, x] = generate_random_levels_bin
    n = 20;
    nb = 10;
    total = n * nb;
    x = zeros(total, 1);
    o = zeros(total, 1);
    
    for i = 1:nb
        ii = (i-1)*n + (1:n);
        % On tire une probabilité aléatoire entre 0.1 et 0.9
        p = 0.1 + (0.9 - 0.1) * rand; 
        x(ii) = p;
        
        % Génération des observations 0/1
        o_block = zeros(n, 1);
        ni = randperm(n);
        ni = ni(1: round(p*n));
        o_block(ni) = 1;
        o(ii) = o_block;
    end
end

% --- LA FONCTION DE PLOT ORIGINALE (Exactement celle que vous m'avez passée) ---
function fig_plot(x,v,lr,m,y)
    fpos0 = [0.2 0.0800 .55*1.0000 .7*0.8133];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsl = getdefaults('fsl'); fsA = getdefaults('fsA'); xsA = getdefaults('xsA');
    ysA = getdefaults('ysA'); abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Color','w','NumberTitle','off','Name','Random Levels Study');
    set(gcf,'units','normalized','position',fpos0);

    % Colonne 1 : Linear
    nr = 3; nc = 2; sub_plts = [1 3 5];
    yl = [0 .5; .5 .9; -2.5 2.5]; % Ajusté pour voir les sauts jusqu'à 2
    j = 1;
    h = sim_A_plot(nr,nc,sub_plts,x(:,j),y(:,j),v(:,j),lr(:,j),m(:,j),yl);
    for i=1:3
        text(xsA,ysA,abc(i),'fontsize',fsA,'Unit','normalized','fontname',fn,'parent',h(i));
    end
    text(.5,yst,'Linear (Random)','fontsize',fst,'Unit','normalized','fontname',fnt,'parent',h(1),'HorizontalAlignment','Center','fontweight','bold');

    % Colonne 2 : Binary
    sub_plts = [2 4 6];
    yl = [.05 .25; .3 .7; -.1 1.1];
    j = 2;
    h = sim_A_plot(nr,nc,sub_plts,x(:,j),y(:,j),v(:,j),lr(:,j),m(:,j),yl);
    for i=1:3
        text(xsA,ysA,abc(i+3),'fontsize',fsA,'Unit','normalized','fontname',fn,'parent',h(i));
    end
    legend(h(3),{'Predicted','True'},'fontsize',fsl,'location','east');
    text(.5,yst,'Binary (Random)','fontsize',fst,'Unit','normalized','fontname',fnt,'parent',h(1),'HorizontalAlignment','Center','fontweight','bold');
end