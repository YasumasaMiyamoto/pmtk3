% Compare various joint density models on binary datsets
% We visualize the learned structuers and evaluated loglik on test set


%% Data

if 1
  loadData('20news_w100');
  % documents, wordlist, newsgroups, groupnames
   tags = double(full(documents))'; % 16,642 documents by 100 words  (sparse logical  matrix)
  nodeNames = wordlist;
  dataName = 'newsgroups';
else
  loadData('sceneContextSUN09', 'ismatfile', false)
  load('SUN09data')
  % 8684 images x 111 tags
  % we merge the training and test data into one big blob
  % so that we can use CV
  tags = [data.train.presence; data.test.presence];
  nodeNames = data.names;
  clear data
  dataName = 'SUN09';
end

% Where to store plots (set figFolder = [] to turn of printing)
if isunix
  figFolder = '/home/kpmurphy/Dropbox/figures/googleJointModelsTalk';
end
if ismac
  figFolder = '/Users/kpmurphy/Dropbox/figures/googleJointModelsTalk';
end

%% Models/ methods

methods = [];
m = 0;

m = m + 1;
methods(m).modelname = 'indep';
methods(m).fitFn = @(labels) discreteFit(labels);
methods(m).logprobFn = @(model, labels) discreteLogprob(model, labels);

m = m + 1;
methods(m).modelname = 'tree';
methods(m).fitFn = @(labels) treegmFit(labels);
methods(m).logprobFn = @(model, labels) treegmLogprob(model, labels);


%{
% For debugging - an empty dag should be the same as the independent model
m = m + 1;
methods(m).modelname = 'dgm-empty';
methods(m).fitFn = @(labels) dgmFitStruct(labels, 'nodeNames', nodeNames, 'emptyGraph', true);
methods(m).logprobFn = @(model, labels) dgmLogprob(model, 'obs', labels);
%}



%{
% For debugging - if we initialize search at a tree and perform 0
% iterations of DAG search, we should get the same resutls as treegmFit
m = m + 1;
methods(m).modelname = 'dgm-tree';
methods(m).fitFn = @(labels) dgmFitStruct(labels, 'nodeNames', nodeNames, 'maxFamEvals', 500, ...
  'figFolder', figFolder, 'nrestarts', 0, 'maxIter', 0, 'initMethod', 'tree');
methods(m).logprobFn = @(model, labels) dgmLogprob(model, 'obs', labels);
%}

%{
% Using no edge restrictions is very slow!
m = m + 1;
methods(m).modelname = 'dgm-init-tree-restrict-none';
methods(m).fitFn = @(labels) dgmFitStruct(labels, 'nodeNames', nodeNames, 'maxFamEvals', 500, ...
  'figFolder', figFolder, 'nrestarts', 2, 'initMethod', 'tree', 'edgeRestrict', 'none');
methods(m).logprobFn = @(model, labels) dgmLogprob(model, 'obs', labels);
%}

m = m + 1;
methods(m).modelname = 'dgm-init-empty-restrict-MI';
methods(m).fitFn = @(labels) dgmFitStruct(labels, 'nodeNames', nodeNames, 'maxFamEvals', 1000, ...
  'figFolder', figFolder, 'nrestarts', 2, 'initMethod', 'empty', 'edgeRestrict', 'MI');
methods(m).logprobFn = @(model, labels) dgmLogprob(model, 'obs', labels);

m = m + 1;
methods(m).modelname = 'dgm-init-tree-restrict-MI';
methods(m).fitFn = @(labels) dgmFitStruct(labels, 'nodeNames', nodeNames, 'maxFamEvals', 1000, ...
  'figFolder', figFolder, 'nrestarts', 2, 'initMethod', 'tree', 'edgeRestrict', 'MI');
methods(m).logprobFn = @(model, labels) dgmLogprob(model, 'obs', labels);

m = m + 1;
methods(m).modelname = 'dgm-init-tree-restrict-L1';
methods(m).fitFn = @(labels) dgmFitStruct(labels, 'nodeNames', nodeNames, 'maxFamEvals', 1000, ...
  'figFolder', figFolder, 'nrestarts', 2, 'initMethod', 'tree', 'edgeRestrict', 'L1');
methods(m).logprobFn = @(model, labels) dgmLogprob(model, 'obs', labels);


m = m + 1;
methods(m).modelname = 'mix5';
methods(m).fitFn = @(labels) mixModelFit(labels, 5, 'discrete');
methods(m).logprobFn = @(model, labels) mixModelLogprob(model, labels);



Nmethods = numel(methods);


%% CV
setSeed(0);
N = size(tags,1);
Nfolds = 3;
if Nfolds == 1
  N2 = floor(N/2);
  % it is important to shuffle the rows to eliminate ordering effects
  perm = randperm(N);
  trainfolds{1}  = perm(1:N2);
  testfolds{1} = setdiff(1:N, trainfolds{1});
  
  %trainfolds{1} = 1:N;
  %testfolds{1} = 1:N;
else
  randomize = true;
  [trainfolds, testfolds] = Kfold(N, Nfolds, randomize);
end

loglik_models = zeros(Nfolds, Nmethods);
 

for fold=1:Nfolds
  fprintf('fold %d of %d\n', fold, Nfolds);
 
  % we convert the labels from {0,1} to {1,2}
  train.labels = tags(trainfolds{fold}, :)+1;
  test.labels = tags(testfolds{fold}, :)+1;
 
  
  models = cell(1, Nmethods);
  methodNames = cell(1, Nmethods);
  for m=1:Nmethods
    methodNames{m} = sprintf('%s', methods(m).modelname); 
    fprintf('fitting %s\n', methodNames{m});
    models{m} = methods(m).fitFn(train.labels);
  end
  
  Ntest = size(test.labels, 1);
  ll = zeros(Ntest, Nmethods);
  for m=1:Nmethods
    fprintf('evaluating %s\n', methodNames{m});
    ll(:, m) = methods(m).logprobFn(models{m}, test.labels);
  end
  loglik_models(fold, :) = sum(ll, 1)/Ntest;
  
end % fold



%% Plot performance

[styles, colors, symbols, plotstr] =  plotColors();


% NLL on labels
figure;
if Nfolds==1
  plot(-loglik_models, 'x', 'markersize', 12, 'linewidth', 2)
  axis_pct
else
  boxplot(-loglik_models)
end
set(gca, 'xtick', 1:Nmethods)
%set(gca, 'xticklabel', methodNames)
xticklabelRot(methodNames, 45);
title(sprintf('negloglik on %s', dataName))
fname = fullfile(figFolder, sprintf('negloglik-%s.png', dataName));
print(gcf, '-dpng', fname);


%% Visualize models themselves


m = strfindCell('tree', methodNames);
if ~isempty(m)
  tree = models{m};
  % The tree is undirected, but for some reason, gviz makes directed graphs
  % more readable than undirected graphs
  fname = fullfile(figFolder, sprintf('tree-%s', dataName))
  graphviz(tree.edge_weights, 'labels', nodeNames, 'directed', 1, 'filename', fname);
end

m = strfindCell('dgm', methodNames);
if ~isempty(m)
  dgm = models{m};
  % The node names get permuted so we must use dgm.nodeNames
  fname = fullfile(figFolder, sprintf('dgm-%s', dataName))
  graphviz(dgm.G, 'labels', dgm.nodeNames, 'directed', 1, 'filename', fname);
end

m = strfindCell('mix5', methodNames);
if ~isempty(m)
  mix = models{m};
  K = mix.nmix;
  [nr,nc] = nsubplots(K);
  figure;
  for k=1:K
    T = squeeze(mix.cpd.T(k,2,:));
    ndx = topAboveThresh(T, 5, 0.1);
    memberNames = sprintf('%s,', nodeNames{ndx});
    disp(memberNames)
    subplot(nr, nc, k)
    bar(T);
    title(sprintf('%5.3f', mix.mixWeight(k)))
  end
end


%{
% Fit a depnet to the labels
%model = depnetFit(tags, 'nodeNames', nodeNames, 'method', 'ARD');
model = depnetFit(tags, 'nodeNames', nodeNames, 'method', 'MI');
fname = fullfile(figFolder, sprintf('depnet-MI-%s', dataName))
graphviz(model.G, 'labels', nodeNames, 'directed', 1, 'filename', fname);
%}


