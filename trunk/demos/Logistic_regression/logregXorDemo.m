%% Apply L2 Logistic Regression to the XOR problem
% We show how an RBF expansion of the features and a polynomial expansion
% 'solves' it, while using raw features does not.
%%
function logregXorDemo()
[X, y] = createXORdata();
lambda = 1e-2;
%% Linear Features
model = logregFit(X, y, 'lambda', lambda);
yhat = logregPredict(model, X);
errorRate = mean(yhat ~= y);
fprintf('Error rate using raw features: %2.f%%\n', 100*errorRate);
plotDecisionBoundary(X, y, @(X)logregPredict(model, X));
title('linear');
printPmtkFigure('logregXorLinear')
%% Basis Expansions
rbfScale = 1;
polydeg  = 2;
kernels = {@(X1, X2)kernelRbfSigma(X1, X2, rbfScale)
           @(X1, X2)kernelPoly(X1, X2, polydeg)};
fnames  = {'logregXorRbf', 'logregXorPoly'};
titles  = {'rbf', 'poly'};

for i=1:numel(kernels)
    preproc.kernelFn = kernels{i};
    model = logregFit(X, y, 'lambda', lambda, 'preproc', preproc);
    yhat = logregPredict(model, X);
    errorRate = mean(yhat ~= y);
    fprintf('Error rate using %s features: %2.f%%\n', titles{i}, 100*errorRate);
    predictFcn = @(Xtest)logregPredict(model, Xtest);
    plotDecisionBoundary(X, y, predictFcn);
    title(titles{i});
    printPmtkFigure(fnames{i})
end
end