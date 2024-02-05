function [tout, yout, simTime] = simulate(obj, x0, u)
% simulate - Simulate the model associated with a Koopman Falsification object.
%
% Syntax:
%    [tout, yout, simTime] = simulate(obj, x0, u)
%
% Description:
%    This function simulates the model associated with a Koopman
%    Falsification (KF) object. The model can be either a Simulink model
%    or a custom function handle. Note that a custom function can be
%    used for simulation by passing the function handle. Ensure that the
%    outputs are consistent with the simulation method used for the
%    specific model.
%
% Inputs:
%    x0  - Initial state vector for simulation
%    u   - Input vector for simulation
%
% Outputs:
%    tout - Time vector of simulation
%    yout - Output vector of simulation
%    simTime  - time taken for simulation
%
% Example:
%    [tout, yout, simTime] = simulate(obj, x0, u);
%
% See also: falsify, sampleSimulation
%
% Author:      Abdelrahman Hekal
% Written:     19-November-2023
% Last update: 4-December-2023
% Last revision: ---
%------------- BEGIN CODE --------------

%interpolate input in accordance with interpolation strategy defined
tsim = (0:obj.dt:obj.T)'; %time points for interpolating input
if ~isempty(u)
    assert(size(u,1)>=2,'Input must have at least two sample points')
    assert(size(u,2)>=2,'Input must have at least two columns, where first column is time points')
    usim = interp1(u(:,1),u(:,2:end),tsim,obj.inputInterpolation,"extrap"); %interpolate and extrapolate input points
    usim =  max(obj.U.inf',min(obj.U.sup',usim)); %ensure that extrapolation is within input bounds
    usim = [tsim,usim];
else
    usim=u; %no input for the model
end
tic;
if isa(obj.model, 'string') || isa(obj.model,"char")
    %skip passing x0 as it is exact and set in the model. TODO: check if
    %needs to be passed
    if all(rad(obj.R0) == 0)
        x0=[];
    end
    [tout, yout] = runSimulink(obj.model, obj.T, x0, usim);
elseif isa(obj.model,'function_handle')
    %function handle must have 3 inputs T,x0,u
    numInputs = nargin(obj.model);
    if numInputs==2
        [tout, yout] = obj.model(obj.T, x0);
    elseif numInputs==3
        [tout, yout] = obj.model(obj.T, x0, usim);
    else
        error(['blackbox function handle must accept 2 or 3 input ' ...
            'arguments, T, x0 and (optional) u'])
    end
    numOutputs = nargout(obj.model);
    assert(numOutputs == 2, ['blackbox function handle must return ' ...
        'two output column vectors,time points and corresponding states']);
elseif isa(obj.model,'OdeFcn')
    [tout,yout]=simulateODE(obj.model,[0,obj.T],x0,usim,obj.inputInterpolation);
elseif isa(obj.model,'ode') %object added to matlab R2023b
    F=obj.model;
    F.InitialValue = x0;
    if nargin(F.ODEFcn) > 2 %odeFcn has inputs
        F.ODEFcn = @(t, x)  F.ODEFcn(t, x, interp1(usim(:,1), usim(:,2:end), t, obj.inputInterpolation, 'extrap')');
    end
    sol = solve(F,0,obj.T);
    tout=sol.Time';
    yout=sol.Solution';
elseif isa(obj.model,'hautomaton') %Staliro hybrid automaton
    initLoc=obj.model.init.loc; %starting location
    assert(isscalar(initLoc),'currently, only exact initial locations are supported');
    assert(isnumeric(initLoc) && initLoc > 0 && mod(initLoc, 1) == 0, 'initial location must be a positive integer');
    %skip first input of x0 which is loc.
    ha_dat.h0=[initLoc 0 x0(2:end)'];
    ha_dat.u=u;
    ht = hasimulator(obj.model,ha_dat,obj.T,'ode45');
    tout=ht(:,2);
    yout=ht(:,[1,3:end]); %get first column representing locs and columns 3:end representing continous states
else
    error('model not supported')
end
simTime=toc;
end