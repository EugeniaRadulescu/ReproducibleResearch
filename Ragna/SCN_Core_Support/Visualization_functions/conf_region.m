function [ax,ci,cen,ub,lb,S,e,lam,Fm,Fc,F,pval] = conf_region(X,varargin)
% [ax,ci,cen,ub,lb,S,e,lam,Fm,Fc,F,pval] = conf_region(X,[doplot])
%
% alternative conf region multivariate based on Johnson & Wichern, 4th ed., p. 236
%
% ax:   axes of confidence region, scaled to be half-length of confidence hyperellipsoid
% ci:   length of axes of conf region (diagonal matrix), axes in reverse order of importance
%       as in ouput of eig
% cen:  center of region (means of variables)
% ub:   upper boundary coordinates for region, rows are dims (vars), cols index coordinates
%       last coordinate is on axis of greatest variation ("reverse order"), from output of eig
% lb:   lower boundary coordinates
%       to plot, try: plot(ub(1,:),ub(2,:),'bo'); hold on; plot(lb(1,:),lb(2,:),'ro')
% S:    covariance matrix
% e     eigenvectors
% lam   eigenvalues
% Fm    degrees of freedom multiplier, p(n-1) / n(n-p)
% Fc    critical F value based on alpha level
% F     F value for test - probably not quite right
% pval  p value for test - probably not quite right
%
% To plot:
% Either enter 1 or color as a 2nd argument, or do it yourself:
%
% [ax,ci,cen,ub,lb,S,e,lam] = conf_region(X);
% b = pinv([X(:,1) ones(size(X,1),1)] ) * X(:,2);
% theta = atan(b(1)) - pi/2;
% [h,h2] = plot_ellipse(cen(1),cen(2),theta,ci(1,1),ci(2,2));
    
doplot = 0;
if length(varargin) > 0, doplot = varargin{1};,end

% -----------------------------------------------------
% * determine multivariate standard deviation matrix S
% -----------------------------------------------------

% center
Xs = X - repmat(mean(X),size(X,1),1);

% covariance matrix S
S = (Xs' * Xs) ./ (size(Xs,1)-1);

% -----------------------------------------------------
% * get squared distance
% -----------------------------------------------------

% squared distance, Johnson & Wichern p. 201
% (X-mean(X))' * inv(S) * (X - mean(X)) generalized to matrices
d = Xs * inv(S) * Xs';
d = diag(d);            % what do the off-diagonals signify?

% -----------------------------------------------------
% * get critical F and coefficient of mult. for axes
% -----------------------------------------------------
p = size(X,2); 
n = size(X,1);
Fm = (p * (n - 1)) ./ (n * (n - p));
a = .95;                                % alpha
Fc = finv(a,p,n - p);                   % critical F
coef = sqrt(Fm .* Fc);

[e,lam] = eig(S);

% -----------------------------------------------------
% * get  F and p-values - this is wrong.
% ratio of squared distances (mahal?) between to within
% -----------------------------------------------------
msb = pdist([mean(X); zeros(1,size(X,2))]); % .^ 2;
msw = sum(d) ./ (n-p);
F = msb / msw;
pval = 1 - fcdf(F,p,n-p);

% nonparametric
niter = 1000;dnull = [];
signv = sign(randn(size(X,1),niter));
for i = 1:niter
    xtmp = X .* repmat(signv(:,i),1,size(X,2));
    dnull(i) = pdist([mean(xtmp); zeros(1,size(X,2))]);
end
pval = sum(msb <= dnull) ./ length(dnull);


% -----------------------------------------------------
% * confidence interval, in units - mult by axes.
% -----------------------------------------------------
ci = ((lam) .^ .5 .* coef);
ax = e * ci;

cen = mean(X)';
lb = repmat(cen,1,size(e,2)) - (e * ci);
ub = repmat(cen,1,size(e,2)) + (e * ci);


if doplot
    % 2-d plot

    % degrees or slope to angle in radians
    %ang = corrcoef(X); ang = ang(1,2);
    %theta = acos(ang-(pi/2));
    %pi * ang / 180

    b = pinv([X(:,1) ones(size(X,1),1)] ) * X(:,2);
    theta = atan(b(1)) - pi/2;
    [h,h2] = plot_ellipse(cen(1),cen(2),theta,ci(1,1),ci(2,2));
    set(h,'Color',[1 1 1],'LineWidth',.5);
    
    if length(doplot) == 3 , set(h2,'FaceColor',doplot);,end
    if ischar(doplot), set(h2,'FaceColor',doplot(1));,end
    
    drawnow
end


return