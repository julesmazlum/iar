function run_all_variations
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));


    % Valeurs à tester pour chaque paramètre
    test_vals = [0.1, 0.5, 0.9];
    
    % On génère les 3 figures demandées
    generate_variation_figure('lambda', test_vals, 0.1, 0.1);
    generate_variation_figure('v0', test_vals, 0.1, 0.1);
    generate_variation_figure('sigma', test_vals, 0.1, 0.1);
end

function generate_variation_figure(param_name, vals, fixed_val1, fixed_val2)
    % Chargement des séries temporelles (fonctions originales)
    [y_lin, x_lin] = timeseries_lin;
    [y_bin, x_bin] = timeseries_bin;
    
    % Initialisation des matrices (Time x Variation)
    vol_multi = cell(1,2); lr_multi = cell(1,2); val_multi = cell(1,2);
    
    for i = 1:length(vals)
        v_curr = vals(i);
        if strcmp(param_name, 'lambda')
            l = v_curr; v0 = fixed_val1; s = fixed_val2;
        elseif strcmp(param_name, 'v0')
            l = fixed_val1; v0 = v_curr; s = fixed_val2;
        else % sigma
            l = fixed_val1; v0 = fixed_val2; s = v_curr;
        end
        
        % Calculs Linear
        [m_l, k_l, v_l] = vkf_lin(y_lin, l, v0, s);
        vol_multi{1}(:,i) = v_l; lr_multi{1}(:,i) = k_l; val_multi{1}(:,i) = m_l;
        
        % Calculs Binary
        [m_b, k_b, v_b] = vkf_bin(y_bin, l, v0, s);
        vol_multi{2}(:,i) = v_b; lr_multi{2}(:,i) = k_b;
        val_multi{2}(:,i) = 1./(1+exp(-m_b)); 
    end
    
    fig_plot_multi([x_lin, x_bin], vol_multi, lr_multi, val_multi, [y_lin, y_bin], param_name, vals);
end

function fig_plot_multi(x, v, lr, m, y, p_name, p_vals)
    % Paramètres de style originaux
    fpos0 = [0.2 0.0800 .55*1.0000 .8*0.8133]; % Légèrement plus haut pour la légende
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Name', ['Effect of ', p_name], 'NumberTitle', 'off', 'Color', 'w');
    set(gcf, 'units', 'normalized', 'position', fpos0);
    
    % Couleurs pour les 3 valeurs (Bleu, Rouge, Vert)
    colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.4660 0.6740 0.1880];
    nr = 3; nc = 2;

    for j = 1:2 % 1:Linear, 2:Binary
        if j == 1
            sub_plts = [1 3 5];
            yl = [0 .8; 0 1; -1.9 1.9];
            title_str = 'Linear';
            idx_abc = 0;
        else
            sub_plts = [2 4 6];
            yl = [0.05 .25; 0.3 0.7; -0.2 1.2];
            title_str = 'Binary';
            idx_abc = 3;
        end
        
        % sim_A_plot prépare les axes et les lignes grises de changement
        h = sim_A_plot(nr, nc, sub_plts, x(:,j), y(:,j), v{j}(:,1), lr{j}(:,1), m{j}(:,1), yl);
        
        for row = 1:3
            axes(h(row)); hold on;
            cla; % Nettoyage pour éviter les superpositions du premier appel
            
            % Tracé des lignes de changement (Gris)
            cp = find(diff(x(:,j)) ~= 0);
            for k = 1:length(cp)
                line([cp(k) cp(k)], ylim, 'Color', [0.8 0.8 0.8], 'HandleVisibility', 'off');
            end
            
            % Tracé des courbes pour chaque valeur de paramètre
            h_lines = []; % Pour capturer les handles de la légende
            for i = 1:length(p_vals)
                if row == 1 % Volatility
                    h_lines(i) = plot(v{j}(:,i), 'Color', colors(i,:), 'LineWidth', 1.5);
                    ylabel('Volatility', 'fontname', fn);
                elseif row == 2 % Learning Rate
                    h_lines(i) = plot(lr{j}(:,i), 'Color', colors(i,:), 'LineWidth', 1.5);
                    ylabel('Learning rate', 'fontname', fn);
                else % Predictions
                    if j == 1, plot(y(:,j), '.', 'Color', [.8 .8 .8], 'HandleVisibility', 'off'); end
                    plot(x(:,j), 'k--', 'LineWidth', 1, 'HandleVisibility', 'off'); % True
                    h_lines(i) = plot(m{j}(:,i), 'Color', colors(i,:), 'LineWidth', 1.5);
                    ylabel('Predictions', 'fontname', fn);
                end
            end
            
            text(xsA, ysA, abc(row + idx_abc), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
            if row == 3, xlabel('Trial', 'fontname', fn); end
        end
        text(.5, yst, title_str, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end

    % --- LÉGENDE GLOBALE ---
    % On crée des noms pour la légende
    labels = cellfun(@(v) sprintf('%s = %.1f', p_name, v), num2cell(p_vals), 'UniformOutput', false);
    
    % On place la légende horizontalement tout en bas
    lgd = legend(h_lines, labels, 'Orientation', 'horizontal', 'FontSize', 10);
    set(lgd, 'Position', [0.4, 0.02, 0.2, 0.03], 'Units', 'normalized'); 
    % Position [x y largeur hauteur] : x=0.4 pour centrer approximativement
end

% --- Fonctions de données (identiques à l'original) ---
function [o,x]=timeseries_lin
    simcat = 'basic'; w = .01; p = [ones(1,2) repmat([-1 1],1,2) -ones(1,4)]; n = 20;
    fname = 'lin.mat'; pipedir = getdefaults('pipedir'); fname = fullfile(pipedir,simcat,fname);
    if ~exist(fname,'file'), nb = length(p); N = nb*n; x = nan(1,N); o = nan(1,N);
        for i=1:nb, ii=(i-1)*n+(1:n); x(ii)=p(i); o(ii)=x(ii)+sqrt(w)*randn(1,n); end
        save(fname,'o','x');
    end
    d=load(fname); o=d.o'; x=d.x';
end

function [o, x] = timeseries_bin
    simcat = 'basic'; p0 = .8; p = [p0*ones(1,2) repmat([1-p0 p0],1,2) (1-p0)*ones(1,4)]; n = 20;
    fname = 'bin.mat'; pipedir = getdefaults('pipedir'); fdir = fullfile(pipedir,simcat); 
    if ~exist(fdir,'dir'), mkdir(fdir); end
    fname = fullfile(fdir,fname);
    if ~exist(fname,'file'), nb = length(p); N = nb*n; x = nan(1,N); o = zeros(1,N); t0 = 0;
        for i=1:nb, ii=t0+(1:n); x(ii)=p(i); ni=randperm(n); ni=ni(1:round(p(i)*n)); o(ii(ni))=1; t0=t0+n; end
        save(fname,'o','x');
    end
    d=load(fname); o=d.o'; x=d.x';
end