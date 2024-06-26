function model = modelF16()
% modelCars - model parameters for the Aircraft Ground Collision Avoidance System (F16).
%
% Syntax:
%       model = modelF16()
%
% Description:
%       Model parameters for the F16 benchmark.
%
% Output Arguments:
%
%       -model:             a koopman falsification model      
%
%------------------------------------------------------------------
    
    model = KF(@run_f16);
    model.R0 = interval([540;deg2rad(2.1215);0;pi/4-pi/20;-(pi/2)*0.8;-pi/4-pi/8;0;0;0;0;0;2338;9;0;0;0],[540;deg2rad(2.1215);0;pi/4+pi/30;-(pi/2)*0.8+pi/20;-pi/4+pi/8;0;0;0;0;0;2338;9;0;0;0]); 

%     model.R0 = interval([540;deg2rad(2.1215);0;pi/4-pi/20;-(pi/2)*0.8;-pi/4-pi/8;0;0;0;0;0;4040;9;0;0;0],[540+0.1;deg2rad(2.1215)+0.1;0+0.1;pi/4+pi/30;-(pi/2)*0.8+pi/20;-pi/4+pi/8;0+0.1;0+0.1;0+0.1;0+0.1;0+0.1;4040+0.1;9+0.1;0+0.1;0+0.1;0+0.1]);
%     model.R0 = interval([540;deg2rad(2.1215);0;pi/4-pi/20;-(pi/2)*0.8;-pi/4-pi/8;0;0;0;0;0;4040;9;0;0;0],[540+0.05;deg2rad(2.1215)+0.05;0+0.05;pi/4+pi/30;-(pi/2)*0.8+pi/20;-pi/4+pi/8;0+0.05;0+0.05;0+0.05;0+0.05;0+0.05;4040+0.05;9+0.05;0+0.05;0+0.05;0+0.05]);
%     model.R0 = interval([540;deg2rad(2.1215);0;pi/4-pi/20;-(pi/2)*0.8;-pi/4-pi/8;0;0;0;0;0;4040;9;0;0;0],[540+0.01;deg2rad(2.1215)+0.01;0+0.01;pi/4+pi/30;-(pi/2)*0.8+pi/20;-pi/4+pi/8;0+0.01;0+0.01;0+0.01;0+0.01;0+0.01;4040+0.01;9+0.01;0+0.01;0+0.01;0+0.01]);


    model.T=15; 
    model.dt = 0.01; 
    model.ak.dt= 0.1; 
    model.nResets=5;
%     model.solver.dt=10;
    model.cp=1500;

    x = stl('x',16);
    eq = globally(x(12)>0,interval(0,15));
    model.spec = specification(eq,'logic');

        % autokoopman settings
    model.ak.obsType="rff";
    model.ak.nObs=20;
    model.ak.gridSlices=5;
    model.ak.opt="grid"; %grid
    model.ak.rank=[1,20,4];


end