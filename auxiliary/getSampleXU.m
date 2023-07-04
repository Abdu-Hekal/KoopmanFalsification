function [x0,u] = getSampleXU(kfModel)
if kfModel.bestSoln.rob==inf %no previous solution, i.e. first iteration or kfModel.trainRand~=2
    [x0,u]=getRandomSampleXU(kfModel);
else
    [x0,u]=getDispSampleXU(kfModel);
end
end

function [x0,u] = getRandomSampleXU(kfModel)
%generate random initial set
x0 = randPoint(kfModel.R0);
%generate random input if kfModel has input.
u=[];
if ~isempty(kfModel.U)
    all_steps = kfModel.T/kfModel.ak.dt;
    if kfModel.pulseInput
        u = randPoint(kfModel.U,all_steps)';
        u = u.*kfModel.cpBool;
    else %piecewise constant input
        for k=1:length(kfModel.cp)
            cp = min(all_steps, kfModel.cp(k)); %control points is minimum of maximum control points and koopman time points (can't have more control points than steps)
            cpVal = randPoint(kfModel.U(1),cp)';
            if all_steps > kfModel.cp(k)
                step = all_steps/kfModel.cp(k);
                assert(floor(step)==step,'number of control points (cp) must be a factor of T/ak.dt');
                (0:kfModel.ak.dt*step:kfModel.T-kfModel.ak.dt)'
                u(:,k) = interp1((0:kfModel.ak.dt*step:kfModel.T-kfModel.ak.dt)', cpVal, linspace(0,kfModel.T-kfModel.ak.dt,all_steps)',kfModel.inputInterpolation,"extrap");
            else
                u(:,k) = cpVal;
            end
        end
    end
    u = [linspace(0,kfModel.T-kfModel.ak.dt,all_steps)',u];
else
    u = [];
end
end

function [x0,u]=getDispSampleXU(kfModel) %TODO: implement control points

u = kfModel.bestSoln.u(:,2:end);
x0 = kfModel.bestSoln.x(1,:)';
uRange = kfModel.U;
x0Range = kfModel.R0;
u1 = size(u, 1);      % Number of time points
u2 = size(u, 2);      % Number of inputs

perturb = 0.05; %max perturbation percentage
lowerBound = [repmat(uRange.inf,size(u,1),1); x0Range.inf];
upperBound = [repmat(uRange.sup,size(u,1),1); x0Range.sup];

u = reshape(u,[],1);
curSample = [u; x0];

maxPerturb = perturb * (upperBound-lowerBound);
lowerBound = max(curSample-maxPerturb,lowerBound); %maximum of perturbation and bounds on inputs
upperBound = min(curSample+maxPerturb,upperBound); %minimum of perturbation and bounds on inputs

newSample = (upperBound - lowerBound) .* rand(size(curSample)) + lowerBound;
newU = newSample(1:u1*u2);
u= [kfModel.bestSoln.u(:,1),reshape(newU,u1,u2)]; %append time from previously found best solution
x0 = newSample(u1*u2+1:end);

end
