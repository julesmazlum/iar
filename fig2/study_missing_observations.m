function study_missing_observations
    % Paramètres originaux
    lambda = 0.1;
    v0 = 0.1;
    sigma = 0.1;
    omega = 0.1; % Pour le binaire
    T = 150;

    % --- GÉNÉRATION DES DONNÉES ---
    % Phase 1 (1-50) : Stable à 1
    % Phase 2 (51-100) : VIDE (on mettra des NaN)
    % Phase 3 (101-150) : Stable à -1 (on change pour voir la réaction)
    
    x_truth = [ones(50,1); -ones(50,1); -ones(50,1)]; % La vérité change à 51 mais on ne voit rien
    y_obs = x_truth + 0.1*randn(T,1);
    
    % On crée le masque de "manque de données"
    is_missing = false(T, 1);
    is_missing(51:100) = true;
    y_obs(is_missing) = NaN; 

    % --- CALCUL VKF ADAPTÉ (LINÉAIRE) ---
    m_l = zeros(T,1); v_l = zeros(T,1); k_l = zeros(T,1); w_l = zeros(T,1);
    m_l(1) = 0; v_l(1) = v0; w_l(1) = v0;

    for t = 2:T
        if is_missing(t)
            % PAS D'OBSERVATION : On ne fait que la prédiction
            m_l(t) = m_l(t-1); 
            v_l(t) = v_l(t-1); 
            w_l(t) = w_l(t-1) + v_l(t-1); % L'incertitude augmente car le temps passe
            k_l(t) = NaN;
        else
            % OBSERVATION PRÉSENTE : Mise à jour standard
            % (Equations 9-13 du papier)
            k_l(t) = (w_l(t-1) + v_l(t-1)) / (w_l(t-1) + v_l(t-1) + sigma^2);
            m_l(t) = m_l(t-1) + k_l(t) * (y_obs(t) - m_l(t-1));
            w_l(t) = (1 - k_l(t)) * (w_l(t-1) + v_l(t-1));
            
            % Update Volatilité (simplifié ici pour la boucle)
            delta_m = (m_l(t)-m_l(t-1))^2;
            v_l(t) = v_l(t-1) + lambda * (delta_m + w_l(t-1) + w_l(t) - 2*w_l(t-1)*(1-k_l(t)) - v_l(t-1));
        end
    end

    % --- CALCUL VKF ADAPTÉ (BINAIRE) ---
    m_b = zeros(T,1); v_b = zeros(T,1); k_b = zeros(T,1); w_b = zeros(T,1);
    m_b(1) = 0; v_b(1) = v0; w_b(1) = v0;
    
    for t = 2:T
        if is_missing(t)
            m_b(t) = m_b(t-1);
            v_b(t) = v_b(t-1);
            w_b(t) = w_b(t-1) + v_b(t-1);
            k_b(t) = NaN;
        else
            % Update binaire (Equations 14-19)
            k_b(t) = (w_b(t-1) + v_b(t-1)) / (w_b(t-1) + v_b(t-1) + omega);
            alpha = sqrt(w_b(t-1) + v_b(t-1));
            m_b(t) = m_b(t-1) + alpha * (y_obs(t) - 1/(1+exp(-m_b(t-1))));
            w_b(t) = (1 - k_b(t)) * (w_b(t-1) + v_b(t-1));
            
            delta_m = (m_b(t)-m_b(t-1))^2;
            v_b(t) = v_b(t-1) + lambda * (delta_m + w_b(t-1) + w_b(t) - 2*w_b(t-1)*(1-k_b(t)) - v_b(t-1));
        end
    end

    % --- TRACÉ ---
    X = [x_truth, 1./(1+exp(-x_truth))]; % Truth
    V = [v_l, v_b];
    LR = [k_l, k_b];
    M = [m_l, 1./(1+exp(-m_b))];
    Y = [y_obs, y_obs];

    fig_plot_missing(X, V, LR, M, Y);
end

function fig_plot_missing(x,v,lr,m,y)
    fpos0 = [0.2 0.0800 .55*1.0000 .7*0.8133];
    fn = getdefaults('fn'); fnt = getdefaults('fnt'); fst = getdefaults('fst');
    fsA = getdefaults('fsA'); xsA = getdefaults('xsA'); ysA = getdefaults('ysA');
    abc = getdefaults('abc'); yst = getdefaults('yst');

    figure('Color','w','Name','Missing Data Study','NumberTitle','off');
    set(gcf,'units','normalized','position',fpos0);

    for j = 1:2 % 1: Linear, 2: Binary
        sub_plts = (j==1)*[1 3 5] + (j==2)*[2 4 6];
        yl = [0 0.5; 0 1.0; -2.5 2.5]; 
        if j==2, yl(3,:) = [-0.1 1.1]; end
        
        h = sim_A_plot(3, 2, sub_plts, x(:,j), y(:,j), v(:,j), lr(:,j), m(:,j), yl);
        
        for row = 1:3
            axes(h(row)); hold on;
            
            % --- AJOUT DES OBSERVATIONS (POINTS GRIS) ---
            % On ne les trace que sur le panneau des PRÉDICTIONS (row 3)
            if row == 3
                % On trace les points y. MATLAB ignore automatiquement les NaN.
                plot(y(:,j), '.', 'Color', [0.7 0.7 0.7], 'MarkerSize', 8); 
                % On remet la ligne de vérité (x) et la prédiction (m) au premier plan
                plot(x(:,j), 'k--', 'LineWidth', 1);
                plot(m(:,j), 'Color', [0.85 0.325 0.098], 'LineWidth', 1.5);
            end
            
            % Zone d'ombre grise pour la période de manque de données
            patch([50 100 100 50], [min(ylim) min(ylim) max(ylim) max(ylim)], ...
                  [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
            
            text(xsA, ysA, abc(row + (j-1)*3), 'fontsize', fsA, 'Unit', 'normalized', 'fontname', fn);
        end
        title_str = 'Linear'; if j==2, title_str = 'Binary'; end
        text(.5, yst, title_str, 'fontsize', fst, 'Unit', 'normalized', 'fontname', fnt, ...
            'parent', h(1), 'HorizontalAlignment', 'Center', 'fontweight', 'bold');
    end
end