function [offsetMap]=bReachCulprit(Bdata,set)
%function that gets idx of predicate (subformula) that is responsible for robustness value

offsetMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
idx=0;
clauses = getClauses(set);
for ij=1:numel(clauses)
    clause = clauses{ij};
    stl=replace(coraBlustlConvert(clause),"(t)","[t]");
    phi = STL_Formula('phi',stl);

    % no point of offset if only one clause with one predicate
    if numel(clauses) <= 1
        mus = STL_ExtractPredicates(phi);
        if numel(mus) <= 1
            return
        end
    end

    [offsetMap,idx] = recursiveOffset(offsetMap,idx,phi,Bdata);
end
end

function [offsetMap,idx] = recursiveOffset(offsetMap,idx,phi,Bdata)
foundCulprit = false;
%compute current robustness and extract all predicates
Rphi = BreachRequirement(phi);
rob=Rphi.Eval(Bdata);
mus = STL_ExtractPredicates(phi);
% Obtain unique values and their counts
uniqueMus={};
counts = {};
signs=[1,-1];
for ii=1:numel(mus)
    pred = mus(ii);
    predStl=regexprep(disp(pred), '\n', '');
    predStl = replace(predStl,'(','');
    predStl = replace(predStl,')','');
    for jj=1:numel(signs)
        modPredStl = strcat(predStl,'+',char(vpa(signs(jj)*rob)));
        stl=regexprep(evalc('display(phi)'), '\n', '');
        pattern = strcat('(.*?)',regexptranslate('escape', predStl),'(.*?)');
        %only count once for each pred
        if jj==1
            index = find(strcmp(predStl, uniqueMus));
            if isempty(index)
                uniqueMus{end+1} = predStl;
                counts{end+1} = 1;
                count=1;
            else
                counts{index} = counts{index}+1;
                count=counts{index};
            end
        end
        modStl = regexprep(stl,pattern,strcat('$1',modPredStl,'$2'),count);
        modPhi = STL_Formula('phi',modStl);
        Rphi = BreachRequirement(modPhi);
        newRob=Rphi.Eval(Bdata);
        if newRob<rob
            offsetMap(idx+ii) = signs(jj)*rob;
            foundCulprit=true;
            if newRob > 0 %not yet offset all responsible predicates
                [offsetMap,idx] = recursiveOffset(offsetMap,idx,modPhi,Bdata);
            else
                idx = idx+numel(mus);
            end
        end
        if foundCulprit
            break;
        end
    end
    if foundCulprit
        break;
    end
end
end
