function [init] = init_stats_model_2019(optInputs)

%Parse the initialization arguments
pathInputs = optInputs.matPath;
concOption = optInputs.concOption; 
legacyOption = optInputs.legacyOption;
sourceOption = optInputs.sourceOption;
mapOption = optInputs.mapOption;

%Specify the alphasNames to relate local names to global names (that differentiate by season)
alphasNames = optInputs.alphasNamesLocal;

%Build the alphasInd and alphasLog structural arrays
alphasNamesList = fieldnames(alphasNames);
alphasNamesAll = {optInputs.alphasStruct(:).name};
indOptim = cell2mat({optInputs.alphasStruct(:).optim});
alphasNamesOptim = alphasNamesAll(indOptim);

[alphasInd,alphasIndOptim,alphasLog,alphasOptim,alphasInit] = deal(struct());
for m = 1:length(alphasNamesList)
    thisAlpha = alphasNamesList{m};
    alphasInd.(thisAlpha) = find(strcmpi(alphasNamesAll,alphasNames.(thisAlpha)));
    if ~isempty(alphasNamesOptim)
        alphasIndOptim.(thisAlpha) = find(strcmpi(alphasNamesOptim,alphasNames.(thisAlpha)));
    end
    alphasLog.(thisAlpha) = optInputs.alphasStruct(alphasInd.(thisAlpha)).log;
    alphasOptim.(thisAlpha) = optInputs.alphasStruct(alphasInd.(thisAlpha)).optim;
    alphasInit.(thisAlpha) = optInputs.alphasStruct(alphasInd.(thisAlpha)).init;
    if alphasLog.(thisAlpha)
        alphasInit.(thisAlpha) = log10(alphasInit.(thisAlpha));
    end
end

%Load model inputs
inData = load(strcat(pathInputs,filesep,optInputs.matName)); %'sources','basin','trimStruct','obs','watershed'

% Convert units from kg/yr to kg/day, the model works in kg/day now
onesGrid = (ones(size(inData.sources.QAtm)));
unitconvert = unit_conversions(onesGrid,'pyr','pday');
sourceFields = fieldnames(inData.sources);
for m = 1:length(sourceFields)
	thisField = sourceFields{m};
	inData.sources.(thisField) = inData.sources.(thisField) .* unitconvert;
end

%Calculate a logical array out of the wetlands for increased speed, only
%used in denitrification
inData.basin.wetlands = (inData.basin.wetlands == 1);
inData.basin.tiles = (inData.basin.tiles == 1);
inData.basin.water = (inData.basin.water == 1);

%Build the harvested array, anywhere that manure or ag chem. fertilizer is applied
inData.basin.harvested = (inData.sources.QMan > 0) | (inData.sources.QAgComm > 0);

%Normalize recharge to the maximum value in the domain
% inData.basin.recharge = inData.basin.recharge/max(inData.basin.recharge(:));

%Normalize recharge fraction to the maximum value in the domain
inData.basin.recharge = inData.basin.rechargeFraction/max(inData.basin.rechargeFraction(:));
inData.basin.recharge(inData.basin.water) = 0;

%Observations Data
if ~concOption
    inData.obs.obs = inData.obs.load; %need loads, not concentrations for observations
else
    inData.obs.obs = inData.obs.conc; %use just concentration
end

% Compute distance between observations
[~,knnDist] = knnsearch([inData.obs.X,inData.obs.Y],[inData.obs.X,inData.obs.Y],'k',11);
inData.obs.nearDist = median(knnDist(:,2:11),2);

% Save to the init structured array
init = struct();

% Run and output options
init.concOption = concOption;
init.legacyOption = legacyOption;
init.mapOption = mapOption;
init.sourceOption = sourceOption;

% Parameter information
init.alphasInd = alphasInd;
init.alphasLog = alphasLog;
init.alphasOptim = alphasOptim;
init.alphasIndOptim = alphasIndOptim;
init.alphasInit = alphasInit;

% Data to pass to optim_stats_model routine
init.sources = inData.sources;
init.basin = inData.basin;
init.trimStruct = inData.trimStruct;
init.obs = inData.obs;
init.watershed = inData.watershed;
