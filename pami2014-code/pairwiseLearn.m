% PAIRWISELEARN Pairwise CRF learning by cross-validation
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

function [params, history] = pairwiseLearn(instance, options);

% initialize parameters
params.unaryWeight = 1.0;
params.pairwiseWeight = 0.0;
params.linEnvCoeffs = [];

if (isempty(instance.pairwise)),
    error('instance must provide list of pairwise terms');
end;

% cross-validate pairwise term
instance.pairwise(:, 3) = params.pairwiseWeight;
y_hat = linEnvInf(params.unaryWeight * instance.unary, ...
    instance.pairwise, [], instance.cliques);

if (options.figWnd > 0),
    figure(options.figWnd);
    subplot(1, 2, 1); colormap(gray); image(255 * reshape(y_hat, [instance.H, instance.W]));
    title(['best inferred labeling (p=0)']);
    drawnow;
end;

history = struct('params', params, 'y_hat', y_hat);

bestLoss = sum(y_hat(:) ~= instance.y(:));
for p = linspace(0.0, 1.0, options.maxIters),
    instance.pairwise(:, 3) = p;
    y_hat = linEnvInf(params.unaryWeight * instance.unary, ...
        instance.pairwise, [], instance.cliques);
    loss = sum(y_hat(:) ~= instance.y(:));
    if (loss < bestLoss),
        bestLoss = loss;
        params.pairwiseWeight = p;

        if (options.figWnd > 0),
            figure(options.figWnd);
            subplot(1, 2, 1); colormap(gray); image(255 * reshape(y_hat, [instance.H, instance.W]));
            title(['best inferred labeling (p=', num2str(p), ')']);
            drawnow;
        end;
        
        history(end + 1) = struct('params', params, 'y_hat', y_hat);
    end;

    % show results
    if (options.figWnd > 0),
        figure(options.figWnd);
        subplot(1, 2, 2); colormap(gray); image(255 * reshape(y_hat, [instance.H, instance.W]));
        title(['inferred labeling with p=', num2str(p)]);
        drawnow;
    end;
end;

