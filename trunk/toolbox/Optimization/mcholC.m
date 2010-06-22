function [l,d,perm] = mcholC(A,mu)
% alias for mchol for installations missing mex files
if nargin == 1
    [l,d,perm] = mchol(A);
else
[l,d,perm] = mchol(A,mu);
end
end