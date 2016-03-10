% PAMI2014
%
% Copyright (c) 2011-2014, Stephen Gould <stephen.gould@anu.edu.au>
% All rights reserved.
%

rand('state', 0);          % initialize random number generator

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

% create checkerboard data (ground-truth cliques)
checkerboard = zeros(instance.H, instance.W);
for i = 1:options.gridStep:instance.H,
    for j = 1:options.gridStep:instance.W,
        rowIndx = (1:options.gridStep) + (i-1);
        colIndx = (1:options.gridStep) + (j-1);
        checkerboard(rowIndx(rowIndx <= instance.H), ...
            colIndx(colIndx <= instance.W)) = max(checkerboard(:) + 1);
    end;
end;

% create groundtruth labels
instance.y = zeros(instance.N, 1);
instance.y = mod(checkerboard(:) + ...
    floor((checkerboard(:) - 1) / ceil(instance.W / options.gridStep) - 1), 2);

% populate cliques to match checkerboard
instance.cliques = checkerboard(:);
instance.numCliques = max(checkerboard(:));

% create noisey observations
eta = [0.1, 0.1];
instance.unary = zeros(size(instance.y, 1), 2);
instance.unary(:, 2) = 2 * (rand(size(instance.y, 1), 1) - 0.5) + ...
    eta(1) * (1 - instance.y) - eta(2) * instance.y;

% no pairwise edges
instance.pairwise = [];

% U+H experiments --------------------------------------------

if (1),
    options.K = 10;
    options.figWnd = options.figWnd + 2;
    compareQPVariants(instance, options);
    
    options.K = 50;
    options.figWnd = options.figWnd + 2;
    compareQPVariants(instance, options);

    eta = [0.5, 0.1];
    instance.unary(:, 2) = 2 * (rand(size(instance.y, 1), 1) - 0.5) + ...
        eta(1) * (1 - instance.y) - eta(2) * instance.y;

    options.K = 10;
    options.figWnd = options.figWnd + 2;
    compareQPVariants(instance, options);

    options.K = 50;
    options.figWnd = options.figWnd + 2;
    compareQPVariants(instance, options);
end;

% U+P+H experiments ---------------------------------------------

if (1),
    % add pairwise edges
    u = repmat(0:instance.W - 1, [instance.H - 1, 1]) * instance.H + ...
        repmat((1:instance.H - 1)', [1, instance.W]);
    v = repmat(0:instance.W - 2, [instance.H, 1]) * instance.H + ...
        repmat((1:instance.H)', [1, instance.W - 1]);
    instance.pairwise = [u(:), u(:) + 1, zeros(size(u(:))); 
        v(:), v(:) + instance.H, zeros(size(v(:)))];

    eta = [0.1, 0.1];
    instance.unary(:, 2) = 2 * (rand(size(instance.y, 1), 1) - 0.5) + ...
        eta(1) * (1 - instance.y) - eta(2) * instance.y;

    options.K = 10;
    options.figWnd = options.figWnd + 2;
    compareQPVariants(instance, options);
    
    eta = [0.5, 0.1];
    instance.unary(:, 2) = 2 * (rand(size(instance.y, 1), 1) - 0.5) + ...
        eta(1) * (1 - instance.y) - eta(2) * instance.y;

    options.K = 10;
    options.figWnd = options.figWnd + 2;
    compareQPVariants(instance, options);
end;

% misspecified clique experiments -------------------------------

if (1),

    % create noisey observations
    eta = [0.1, 0.1];
    instance.unary = zeros(size(instance.y, 1), 2);
    instance.unary(:, 2) = 2 * (rand(size(instance.y, 1), 1) - 0.5) + ...
        eta(1) * (1 - instance.y) - eta(2) * instance.y;

    if (1),
        % no pairwise edges
        instance.pairwise = [];
    else
        % add pairwise edges
        u = repmat(0:instance.W - 1, [instance.H - 1, 1]) * instance.H + ...
            repmat((1:instance.H - 1)', [1, instance.W]);
        v = repmat(0:instance.W - 2, [instance.H, 1]) * instance.H + ...
            repmat((1:instance.H)', [1, instance.W - 1]);
        instance.pairwise = [u(:), u(:) + 1, zeros(size(u(:))); 
            v(:), v(:) + instance.H, zeros(size(v(:)))];
    end;    
    
    % experiment parameters
    cliqueReduction = [0.05, 0.10, 0.25, 0.5];
    numSegs = [1, 2, 5];
    ratioCorrupt = 0.1;
    
    for n = 1:length(numSegs),                
        for c = 1:length(cliqueReduction),
            % create reduced cliques
            instance.cliques = checkerboard(:);
            instance.numCliques = max(checkerboard(:));
            for i = 2:numSegs(n),
                instance.cliques(:, i) = instance.cliques(:, i - 1) + instance.numCliques;
            end;
                        
            instance.numCliques = max(instance.cliques(:));
            
            indx = find(rand(size(instance.cliques)) < cliqueReduction(c));
            instance.cliques(indx) = 0;
            
            % create noisy cliques
            noiseCliques = floor(ratioCorrupt * instance.numCliques);            
            cliqueSize = ceil(instance.N / (options.gridStep^2));
            for i = 1:noiseCliques,
                instance.cliques(:, end + 1) = zeros(instance.N, 1);
                indx = find(rand(instance.N, 1) < 1 / cliqueSize);
                instance.cliques(indx, end) = instance.numCliques + i;
            end;
            instance.numCliques = instance.numCliques + noiseCliques;
                        
            % learn the parameters
            options.learningQP = 1;
            [params, hist] = linEnvLearn(instance, options);
    
            % plot results
            figure(max([1, options.figWnd]));
            subplot(length(numSegs), length(cliqueReduction), ...
                (n - 1) * length(cliqueReduction) + c);
            imagesc(reshape(hist(end).y_hat, [instance.H, instance.W]));
            axis off;
            title(['(', num2str(cliqueReduction(c)), ', ', int2str(numSegs(n)), ')']);
            colormap(gray);
            drawnow;
            
            % write results
            if (0),
               imwrite(reshape(255 * hist(end).y_hat, [instance.H, instance.W]), ...
                   ['synth_corrupt_', int2str(n), '_', int2str(c), '.png']);
            end;
        end;
    end;
end;
