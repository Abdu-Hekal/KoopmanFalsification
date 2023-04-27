function repArch22()
% arch22ModelTransmission - runs all requirement formula for the
%  model transmission benchmark of the ARCH'22 falsification Category
%
% Syntax:
%   results = repArch22()
%
% Inputs:
%    -
%
% Outputs:
%    results -
%

% Author:       Abdelrahman Hekal
% Written:      23-Feb-2023
% Last update:  ---
% Last revision:---

%------------- BEGIN CODE --------------
model = model_AutoTransmission();
model.trainRand=2;      
x = stl('x',3);
requirements = {; ...
%         "AT1", globally(x(1) < 120,interval(0,20)); ...
%     "AT2", globally(x(2) < 4750,interval(0,10)); ...
    %     "testAT2", globally(x(2) <= 4750,interval(0,10)); ...
%         "AT51", globally(implies(~(x(3)<=1 & x(3)>=1) & finally(x(3)>=1 & x(3)<=1,interval(0.001,0.1)),finally(globally(x(3)>=1 & x(3)<=1,interval(0,2.5)),interval(0.001,0.1))),interval(0,30)); ...
         "AT6a", implies(globally(x(2)<3000,interval(0,30)),globally(x(1)<35,interval(0,4))); ...
%          "AT6b", implies(globally(x(2)<3000,interval(0,30)),globally(x(1)<50,interval(0,8))); ...
%          "AT6c", implies(globally(x(2)<3000,interval(0,30)),globally(x(1)<65,interval(0,20))); ...

    %         "test", globally(x(1)<50 | x(1)>60,interval(10,30)),...
    %      "testAT6a", implies(globally(x(2)<3000,interval(0,4)),globally(x(1)<35,interval(0,4))); ...

    };

solns=dictionary(string.empty,cell.empty);
for i = 1:size(requirements, 1)
    for j = 1:10
        disp("--------------------------------------------------------")
        name = requirements{i, 1};
        eq = requirements{i, 2};

        model.spec = specification(eq,'logic');
        [model,~] = falsify(model);

        if j==1
            solns(name)={{model.soln}};
        else
            soln=solns(name);
            soln{1}{end+1}=model.soln;
            solns(name)=soln;
        end
    end
    avgKoopTime=mean(getMetrics(solns(name),'koopTime'));
    avgMilpSetupTime=mean(getMetrics(solns(name),'milpSetupTime'));
    avgMilpSolveTime=mean(getMetrics(solns(name),'milpSolvTime'));
    avgRuntime=mean(getMetrics(solns(name),'runtime'));
    avgTrain=mean(getMetrics(solns(name),'trainIter'));
    sims=getMetrics(solns(name),'sims');
    avgSims=mean(sims);
    medianSims=median(sims);
    avgFalsified=sum(getMetrics(solns(name),'falsified'));
    %print info
    fprintf('Benchmark: %s\n', name);
    fprintf('Number of runs: %d\n', j);
    fprintf('Avg koopman time: %.2f seconds\n', avgKoopTime);
    fprintf('Avg milp setup time: %.2f seconds\n', avgMilpSetupTime);
    fprintf('Avg milp solve time: %.2f seconds\n', avgMilpSolveTime);
    fprintf('Avg total runtime: %.2f seconds\n', avgRuntime);
    fprintf('Avg training iterations: %.2f\n', avgTrain);
    fprintf('Avg Number of simulations: %.2f\n', avgSims);
    fprintf('Median Number of simulations: %.2f\n', medianSims);
    fprintf('Number of successful falsified traces: %d/%d\n', avgFalsified,j);

end
save("solns.mat","solns")
end

function list = getMetrics(solns,metric)
    list=[];
    for i=1:length(solns{1})
        list=[list,solns{1}{i}.(metric)];
    end
end
