function study_extreme_cases
    % Trouve le dossier où se trouve ce fichier fig2.m
    path_actuel = fileparts(mfilename('fullpath'));
    
    % Ajoute le sous-dossier 'lib' au chemin de recherche
    addpath(fullfile(path_actuel, '../lib'));

    % Paramètres standards
    lambda = 0.1; v0 = 0.1; sigma = 0.1;
    T = 150; % Nombre d'essais

    % --- SCÉNARIO 1 : LE BLACK SWAN (Outlier) ---
    x1 = ones(T, 1); 
    y1 = x1 + 0.05*randn(T, 1);
    y1(75) = -4; % L'intrus massif au milieu d'un monde stable

    % --- SCÉNARIO 2 : LA RAMPE (Trend) ---
    x2 = linspace(-1, 1, T)'; 
    y2 = x2 + 0.05*randn(T, 1);

    % --- SCÉNARIO 3 : LE PIÈGE DU BRUIT (High Noise) ---
    x3 = zeros(T, 1);
    x3(75:end) = 0.2; % Un tout petit changement...
    y3 = x3 + 0.8*randn(T, 1); % ...noyé dans un bruit énorme

    scenarios = {'Black Swan', 'The Ramp', 'Noise Trap'};
    data_y = {y1, y2, y3};
    data_x = {x1, x2, x3};

    for i = 1:3
        % Calcul VKF (Linear car c'est plus parlant pour les extrêmes)
        [m, k, v] = vkf_lin(data_y{i}, lambda, v0, sigma);
        
        % Tracé
        plot_extreme(data_x{i}, data_y{i}, v, k, m, scenarios{i});
    end
end

function plot_extreme(x, y, v, lr, m, tag)
    fpos = [0.2 0.1 .4 .75];
    fn = getdefaults('fn'); 
    figure('Name', ['Extreme: ' tag], 'Color', 'w', 'NumberTitle', 'off');
    set(gcf, 'units', 'normalized', 'position', fpos);

    % Panel A: Volatility
    subplot(3,1,1); hold on;
    plot(v, 'r', 'LineWidth', 1.5);
    ylabel('Volatility'); title(tag);
    grid on;

    % Panel B: Learning Rate
    subplot(3,1,2); hold on;
    plot(lr, 'b', 'LineWidth', 1.5);
    ylabel('Learning Rate');
    grid on;

    % Panel C: Predictions
    subplot(3,1,3); hold on;
    plot(y, '.', 'Color', [.8 .8 .8]); % Observations
    plot(x, 'k--', 'LineWidth', 1);    % Truth
    plot(m, 'Color', [0 .5 0], 'LineWidth', 1.5); % Model
    ylabel('Predictions'); xlabel('Trial');
    legend('Obs', 'True', 'VKF', 'Location', 'Best');
    grid on;
end