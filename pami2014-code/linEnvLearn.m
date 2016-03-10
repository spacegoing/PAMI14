% LINENVLEARN   Lower linear enevelope max-margin learning
%
% This is a reference implementation for the synthetic experiments on lower
% linear enevelope inference and learning described in
%
%    "Max-margin Learning for Lower Linear Envelope Potentials in Binary
%    Markov Random Fields", Stephen Gould, ICML 2011.
%
% Copyright (c) 2011-2014, Stephen Gould <stephen.gould@anu.edu.au>
% All rights reserved.
%

function [params, history] = linEnvLearn(instance, options);

% true feature vector
    truePhi = featureVector(instance, instance.y, options);

    % initialize parameters
    params.unaryWeight = 1.0;
    params.pairwiseWeight = 0.0;
    params.linEnvCoeffs = zeros(options.K, 2);

    numVariables = instance.N;
    numParameters = options.K + 3; % unary, pairwise and linear envelope coefficients

    % construct QP objective
    P = eye(numParameters + 1, numParameters + 1);
    P(end, end) = 0.0;
    q = zeros(size(P, 1), 1);
    q(end) = 1.0e3;

    % positivity constraint on pairwise weight
    G = [0, 1, zeros(1, numParameters - 1)];
    h = [0];

    % construct non-decreasing concave constraint
    if (options.K > 1),
        switch options.learningQP,
          case 1
            Dxx = toeplitz([-1 zeros(1, options.K - 2)], [-1 2 -1 zeros(1, options.K - 2)]);
            G = [G; zeros(size(Dxx, 1), numParameters - options.K - 1), Dxx, zeros(size(Dxx, 1), 1)];
            h = [h; zeros(size(Dxx, 1), 1)];
          case 2    
            Dx = toeplitz([1 zeros(1, options.K - 2)], [1 -1 zeros(1, options.K - 2)]);
            G = [G; zeros(size(Dx, 1), numParameters - options.K), Dx, zeros(size(Dx, 1), 1)];
            h = [h; zeros(size(Dx, 1), 1)];
          case 3
            G = [G; zeros(options.K - 1, 4), eye(options.K - 1), zeros(options.K - 1, 1)];
            h = [h; zeros(options.K - 1, 1)];
        end;
    end;

    % positivity constraint on slack
    G = [G; zeros(1, numParameters), 1];
    h = [h; 0];

    % iterate until convergence
    theta = zeros(numParameters + 1, 1);
    for t = 1:options.maxIters,
        % solve max-margin qp
        warning off;
        theta = quadprog(P, q, -1.0 * G, -1.0 * h, [], [], [], [], theta);
        warning on;
        
        % decode parameters
        params.unaryWeight = theta(1);
        params.pairwiseWeight = max([0.0, theta(2)]);
        if (~isempty(instance.pairwise)),
            instance.pairwise(:, 3) = params.pairwiseWeight;
        end;

        switch options.learningQP,
          case 1
            params.linEnvCoeffs(1, 2) = theta(3);
            for k = 1:options.K,
                params.linEnvCoeffs(k, 1) = theta(k + 3) - theta(k + 2);
            end;
          case 2
            params.linEnvCoeffs(1, 2) = theta(3);            
            params.linEnvCoeffs(1, 1) = theta(4);
            for k = 2:options.K,
                params.linEnvCoeffs(k, 1) = theta(k + 3);
            end;
          case 3
            params.linEnvCoeffs(1, 2) = theta(3);            
            params.linEnvCoeffs(1, 1) = theta(4);
            for k = 2:options.K,
                params.linEnvCoeffs(k, 1) = params.linEnvCoeffs(k - 1, 1) - theta(k + 3);
            end;
        end;

        for k = 2:options.K,
            params.linEnvCoeffs(k, 2) = params.linEnvCoeffs(k - 1, 2) + ...
                (k - 1) * (params.linEnvCoeffs(k - 1, 1) - params.linEnvCoeffs(k, 1));
        end;
        params.linEnvCoeffs(:, 1) = params.linEnvCoeffs(:, 1) * options.K;
        
        % infer solution
        y_hat = linEnvInf(params.unaryWeight * instance.unary, ...
                          instance.pairwise, params.linEnvCoeffs, instance.cliques);

        % update history
        history(t) = struct('params', params, 'y_hat', y_hat);
        
        % show results for this iteration
        if (0) && (options.figWnd > 0),
            figure(options.figWnd);
            subplot(1, 2, 1);
            plotLinearEnvelope(params);
            title('linear envelope');
            subplot(1, 2, 2); colormap(gray); image(255 * reshape(y_hat, [instance.H, instance.W]));
            title('inferred labeling');
            drawnow;
        end;
        
        % infer most violated constraint
        lossUnary = zeros(instance.N, 2);
        lossUnary(instance.y == 1, 1) = 1.0 / instance.N;
        lossUnary(instance.y == 2, 2) = 1.0 / instance.N;
        y_loss = linEnvInf(params.unaryWeight * instance.unary - lossUnary, ...
                           instance.pairwise, params.linEnvCoeffs, instance.cliques);
        
        % add constraint
        phi = featureVector(instance, y_loss, options);
        loss = sum(y_loss(:) ~= instance.y(:)) / numVariables;
        slack = loss - (phi - truePhi) * theta(1:end - 1);
        violation = slack - theta(end);
        disp(['iter = ', int2str(t), ...
              ', loss = ', num2str(sum(y_hat(:) ~= instance.y(:)) / numVariables), ...
              ', max-violation = ', num2str(violation)]);
        
        % check for convergence
        if (violation < options.eps), disp('converged'); break; end;
        
        G = [G; phi - truePhi, 1];
        h = [h; loss];
    end
end

% feature vector --------------------------------------------------------

function [phi] = featureVector(instance, y_hat, options);

    unaryPhi = sum(instance.unary(y_hat == 0, 1)) + ...
        sum(instance.unary(y_hat == 1, 2));
    pairwisePhi = 0;
    if (~isempty(instance.pairwise)),
        pairwisePhi = sum(y_hat(instance.pairwise(:, 1)) ~= y_hat(instance.pairwise(:, 2)));
    end;

    highOrderPhi = zeros(1, options.K + 1);
    for m = 1:instance.numCliques,
        indx = mod(find(instance.cliques == m) - 1, instance.N) + 1;
        p = sum(y_hat(indx)) / length(indx);
        k = floor(p * options.K);
        highOrderPhi(k + 1) = highOrderPhi(k + 1) + k - p * options.K + 1;
        if (k < options.K),
            highOrderPhi(k + 2) = highOrderPhi(k + 2) + p * options.K - k;
        end;
    end;

    if (options.learningQP == 2),
        highOrderPhi = highOrderPhi * tril(ones(length(highOrderPhi)));
    end;

    if (options.learningQP == 3),
        highOrderPhi = zeros(1, options.K + 1);
        for m = 1:instance.numCliques,
            highOrderPhi(1) = highOrderPhi(1) + 1;
            indx = mod(find(instance.cliques == m) - 1, instance.N) + 1;
            p = sum(y_hat(indx)) / length(indx);
            highOrderPhi(2) = highOrderPhi(2) + p * options.K;
            indx = 2:(ceil(p * options.K));
            highOrderPhi(indx + 1) = highOrderPhi(indx + 1) + (indx - 1) - p * options.K;
        end;
    end;

    phi = [unaryPhi, pairwisePhi, highOrderPhi];
    return;

% plot linear envelope ---------------------------------------------------

function plotLinearEnvelope(params);
    K = size(params.linEnvCoeffs, 1);
    env = zeros(K + 1, 1);    

    env(1) = params.linEnvCoeffs(1, 2);
    for k = 1:K,
        env(k + 1) = env(k) + params.linEnvCoeffs(k, 1) / K;
    end;

    env = env / abs(params.unaryWeight);
    plot(env, 'lineWidth', 2);
    a = axis; axis([1, K + 1, a(3), a(4)]); grid on;
    return;
