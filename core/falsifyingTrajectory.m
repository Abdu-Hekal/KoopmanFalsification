function [x0,u] = falsifyingTrajectory(kfModel)
% extract the most critical initial state and input signal from the most
% critical reachable set and specification

%setup
R0=kfModel.R0;
U=kfModel.U;
cpBool=kfModel.cpBool;
set=kfModel.soln.set;
alpha=kfModel.soln.alpha;

% determine most critical initial state
alphaInit = zeros(size(set.expMat,1),1);
temp = prod(ones(size(set.expMat))-mod(set.expMat,2),1);
expMat = set.expMat(:,temp == 0);

ind = find(sum(expMat,1) == 1);

for i = 1:size(set.expMat,1)
    for j = ind
        if expMat(i,j) == 1
            alphaInit(i) = alpha(j);
        end
    end
end

R0 = zonotope(R0);
G_R0_ = generators(R0);
%FIXME: AH modification, ensures that generators is n*n matrix, appends zeros for
%dimensions with exact x0
G_R0 = zeros(size(generators(R0),1));
[row ,col]=find(G_R0_);
for ii=1:numel(row)
    G_R0(row(ii),row(ii)) = G_R0_(row(ii),col(ii));
end

%AH modification, checks if R0 is not exact, to avoid error
if isempty(generators(R0))
    x0 = center(R0);
else
    x0 = center(R0) + G_R0*alphaInit;
end
%check if kfModel has control input
if ~isempty(U)
    % determine most ctritical control input
    if ~isempty(set.Grest)

        if kfModel.pulseInput %if pulse input
            %initialise alpha to cpBool
            alphaU = reshape(cpBool,[],1);
            %input alpha returned by milp optimizernon
            allAlpha = alpha(size(set.G,2)+1:end);
            %find all nonzero elements in the relevant time horizon
            nonzero = find(alphaU,length(allAlpha));
            alphaU(nonzero) = allAlpha;
            %set all nonrelevant inputs after to zero
            alphaU(nonzero(end)+1:end)=0;
        else
            alphaU = alpha(size(set.G,2)+1:end);
        end

        U = zonotope(U); c_u = center(U); G_u = generators(U);
        alphaU = reshape(alphaU,[size(G_u,2),length(alphaU)/size(G_u,2)]);

        u = c_u + G_u*alphaU;
    else
        u = center(U);
    end
else
    u = [];
end
if ~isempty(u)
    all_steps = kfModel.T/kfModel.ak.dt;
    %append time points as first column
    tp_=linspace(0,kfModel.T-kfModel.ak.dt,all_steps); %time points without last time step
    tp = linspace(0,kfModel.T,all_steps+1);
    u = interp1(tp_',u',tp',kfModel.inputInterpolation,"extrap"); %interpolate and extrapolate input points
    u =  max(kfModel.U.inf',min(kfModel.U.sup',u)); %ensure that extrapolation is within input bounds
    u = [tp',u];
end
end