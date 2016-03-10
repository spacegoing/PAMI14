% COMPAREQPVARIANTS
%
% Copyright (c) 2011-2014, Stephen Gould <stephen.gould@anu.edu.au>
% All rights reserved.
%

function compareQPVariants(instance, options);

% learn 0-th, 1-st and 2-nd order methods
options.learningQP = 1;
[params1, hist1] = linEnvLearn(instance, options);

options.learningQP = 2;
[params2, hist2] = linEnvLearn(instance, options);

options.learningQP = 3;
[params3, hist3] = linEnvLearn(instance, options);

% plot results
figure(max([1, options.figWnd]));
subplot(1,1,1);
env = zeros(options.K + 1, 3);
env(1,1) = params1.linEnvCoeffs(1, 2);
env(1,2) = params2.linEnvCoeffs(1, 2);
env(1,3) = params3.linEnvCoeffs(1, 2);
for k = 1:options.K,
    env(k + 1, 1) = env(k, 1) + params1.linEnvCoeffs(k, 1) / options.K;
    env(k + 1, 2) = env(k, 2) + params2.linEnvCoeffs(k, 1) / options.K;
    env(k + 1, 3) = env(k, 3) + params3.linEnvCoeffs(k, 1) / options.K;
end;

env(:, 1) = env(:, 1) / abs(params1.unaryWeight);
env(:, 2) = env(:, 2) / abs(params2.unaryWeight);
env(:, 3) = env(:, 3) / abs(params3.unaryWeight);
h = plot(env, 'lineWidth', 3, 'MarkerSize', 9);
set(h(1), 'Marker', 's'); set(h(2), 'Marker', '^'); set(h(3), 'Marker', 'o');
%a = axis; axis([1, options.K + 1, a(3), a(4)]); grid on;
a = axis; axis([1, options.K + 1, -100, 100]); grid on;
legend(['2^{nd} order (', int2str(length(hist1)), ' iters.)'], ...
    ['1^{st} order (', int2str(length(hist2)), ' iters.)'], ...
    ['0^{th} order (', int2str(length(hist3)), ' iters.)']);

set(gca, 'FontSize', 14);
drawnow;

% plot images
figure(gcf);
subplot(3, 4, 1); imagesc(reshape(instance.y, [instance.H, instance.W]));
axis off; title('groundtruth');
subplot(3, 4, 2); imagesc(reshape(diff(instance.unary, 1, 2), [instance.H, instance.W]));
axis off; title('unary');
subplot(3, 4, 3); imagesc(reshape(hist1(3).y_hat, [instance.H, instance.W]));
axis off; title('iter. 3');
subplot(3, 4, 4); imagesc(reshape(hist1(end).y_hat, [instance.H, instance.W]));
axis off; title('last iter.');

subplot(3, 4, 5); imagesc(reshape(instance.y, [instance.H, instance.W]));
axis off;
subplot(3, 4, 6); imagesc(reshape(diff(instance.unary, 1, 2), [instance.H, instance.W]));
axis off;
subplot(3, 4, 7); imagesc(reshape(hist2(3).y_hat, [instance.H, instance.W]));
axis off;
subplot(3, 4, 8); imagesc(reshape(hist2(end).y_hat, [instance.H, instance.W]));
axis off;

subplot(3, 4, 9); imagesc(reshape(instance.y, [instance.H, instance.W]));
axis off;
subplot(3, 4, 10); imagesc(reshape(diff(instance.unary, 1, 2), [instance.H, instance.W]));
axis off;
subplot(3, 4, 11); imagesc(reshape(hist3(3).y_hat, [instance.H, instance.W]));
axis off;
subplot(3, 4, 12); imagesc(reshape(hist3(end).y_hat, [instance.H, instance.W]));
axis off;
colormap(gray);
drawnow;

