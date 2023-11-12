
% initialize seeds
rng(18)
pyrunfile("seed.py")

kfModel = modelAutoTransmission();
plot_vars = [1,2];

x = stl('x',3);
eq = implies(globally(x(2)<3000,interval(0,30)),globally(x(1)<35,interval(0,4)));
kfModel.spec = specification(eq,'logic');

kfModel.maxSims=5;

[kfModel,trainset] = falsify(kfModel);

if kfModel.soln.falsified
    disp(['simulations required: ',num2str(kfModel.soln.sims)])
    %     visualize_falsification(kfModel.soln.x, kfModel.soln.t, kfModel.spec, plot_vars,'Speed','RPM')
else
    disp("No falsifiying trace found")
end

% visualize_train(trainset, plot_vars,'Speed','Angular velocity')
% export_fig training.pdf