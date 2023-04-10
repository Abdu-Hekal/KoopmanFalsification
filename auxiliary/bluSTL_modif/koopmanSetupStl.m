function Sys = koopmanSetupStl(Sys)

%% STL formula
Fstl = [];
Pstl = [];
var = struct('X',Sys.X);

stlList= KoopmanParseStlLabels(Sys);
M = Sys.bigM;

for i = 1:numel(stlList)
    phi = STLformula('phi', stlList{i});

    [Fphi, Pphi] = KoopmanMilpRobust(phi, 1, Sys.L+1, Sys.dt, var,M);
    
    Pstl = [Pstl; Pphi];
    Fstl = [Fstl Fphi];
end

%if no stl defined
if numel(stlList) == 0
    Pstl = sdpvar(1,1);
end

%assign stl optim variables and constraints
Sys.Fstl=Fstl; Sys.Pstl=Pstl; 



