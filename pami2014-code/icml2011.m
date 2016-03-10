% ICML2011
%
% Runs synthetic experiments described in
% 
%    "Max-margin Learning for Lower Linear Envelope Potentials in Binary
%    Markov Random Fields", Stephen Gould, ICML 2011.
%
% Copyright (c) 2011, Stephen Gould <stephen.gould@anu.edu.au>
% All rights reserved.
%

rand('state', 0);       % initialize random number generator

% options ----------------------------------------------------
options.K = 10;            % number of lower linear functions
options.gridStep = 16;     % grid size for defining cliques
options.maxIters = 100;    % maximum learning iterations
options.eps = 1.0e-16;     % constraint violation threshold
options.learningQP = 1;    % encoding for learning QP (1, 2, or 3)
options.figWnd = -1;       % figure for showing results

% base instance -----------------------------------------------
instance.W = 128;          % image width
instance.H = 128;          % image height
instance.cliques = [];     % mapping of variables to cliques

instance.N = instance.W * instance.H; % number of variables

% populate cliques as a grid
instance.cliques = zeros(instance.H, instance.W);
instance.numCliques = 0;
for i = 1:options.gridStep:instance.H,
    for j = 1:options.gridStep:instance.W,
        rowIndx = (1:options.gridStep) + (i-1);
        colIndx = (1:options.gridStep) + (j-1);
        instance.numCliques = instance.numCliques + 1;
        instance.cliques(rowIndx(rowIndx <= instance.H), ...
            colIndx(colIndx <= instance.W)) = instance.numCliques;
    end;
end;
instance.cliques = instance.cliques(:);

% add pairwise edges
u = repmat(0:instance.W - 1, [instance.H - 1, 1]) * instance.H + ...
    repmat((1:instance.H - 1)', [1, instance.W]);
v = repmat(0:instance.W - 2, [instance.H, 1]) * instance.H + ...
    repmat((1:instance.H)', [1, instance.W - 1]);
instance.pairwise = [u(:), u(:) + 1, zeros(size(u(:))); 
    v(:), v(:) + instance.H, zeros(size(v(:)))];

% create checkerboard data
instance.y = zeros(instance.N, 1);
instance.y = mod(instance.cliques(:, 1) + ...
    floor((instance.cliques(:, 1) - 1) / sqrt(instance.numCliques) - 1), 2);

% create noisey observations
instance.unary = zeros(size(instance.y, 1), 2);
eta = [0.1, 0.1];       % signal-to-noise ratio for black and white pixels
x = 2 * (rand(size(instance.y)) - 0.5) + eta(1) * (1 - instance.y) - eta(2) * instance.y;
eta2 = [0.5, 0.1];      % signal-to-noise ratio for black and white pixels
x2 = 2 * (rand(size(instance.y)) - 0.5) + eta2(1) * (1 - instance.y) - eta2(2) * instance.y;

% learn pairwise crf
instance.unary(:, 2) = x(:);
[~, history] = pairwiseLearn(instance, options);
y_bestPairwise = history(end).y_hat;

% learn pairwise crf
instance.unary(:, 2) = x2(:);
[~, history2] = pairwiseLearn(instance, options);
y_bestPairwise2 = history2(end).y_hat;

% learn higher-order crf
instance.unary(:, 2) = x(:);
instance.pairwise = [];
[parameters, history] = linEnvLearn(instance, options);

% learn higher-order crf
instance.unary(:, 2) = x2(:);
instance.pairwise = [];
[parameters2, history2] = linEnvLearn(instance, options);

% plot results
figure; colormap(gray);
subplot(2, 5, 1); image(255 * reshape(instance.y, [instance.H, instance.W])); axis off; title('ground-truth');
subplot(2, 5, 2); imagesc(reshape(x, [instance.H, instance.W])); axis off; title('data');
subplot(2, 5, 3); imagesc(255 * reshape(y_bestPairwise, [instance.H, instance.W])); axis off; title('pairwise');
subplot(2, 5, 4); imagesc(255 * reshape(history(3).y_hat, [instance.H, instance.W])); axis off; title('iter. 3');
subplot(2, 5, 5); imagesc(255 * reshape(history(end).y_hat, [instance.H, instance.W])); axis off; title('last iter.');

subplot(2, 5, 6); image(255 * reshape(instance.y, [instance.H, instance.W])); axis off;
subplot(2, 5, 7); imagesc(reshape(x2, [instance.H, instance.W])); axis off;
subplot(2, 5, 8); imagesc(255 * reshape(y_bestPairwise2, [instance.H, instance.W])); axis off;
subplot(2, 5, 9); imagesc(255 * reshape(history2(3).y_hat, [instance.H, instance.W])); axis off;
subplot(2, 5, 10); imagesc(255 * reshape(history2(end).y_hat, [instance.H, instance.W])); axis off;

figure;
theta = zeros(options.K + 1, 2);
theta(1,1) = parameters.linEnvCoeffs(1, 2);
theta(1,2) = parameters2.linEnvCoeffs(1, 2);
for k = 1:options.K,
    theta(k + 1, 1) = theta(k, 1) + parameters.linEnvCoeffs(k, 1) / options.K;
    theta(k + 1, 2) = theta(k, 2) + parameters2.linEnvCoeffs(k, 1) / options.K;
end;

plot(theta(:, 1) / parameters.unaryWeight, 'bo-', 'LineWidth', 4);
hold on;
plot(theta(:, 2) / parameters2.unaryWeight, 'rd-', 'LineWidth', 4);
hold off;
legend('\eta = [0.1, 0.1]', '\eta = [0.5, 0.1]');

grid on;
title('Learned lower linear envelopes');
