function [sim,addOutput] = optim_stats_model_2019(params,pre,progress)
%This function is designed to be run by a function such as optim_wrapper.m
%
%params is a structured array defining the values of each of the input
%parameters
%
%pre is structured array containing pre-calculated values, generated by an
%initialization function such as init_stats_model_YYYY.m
%
%progress is a logical true/false value to show a progress bar, true by
%default
%
% Output is simulated values for each watershed in order of watershedList
%
% Secondarily, additional outputs can be requested that will depend on the
% options selected in the model master. `addOutput` will be a structured
% array.

% Process the input arguments
if nargin < 3
    progress = true;
end

%Calculate parameters, distribute to grids as needed
onesGrid = (ones(size(pre.sources.QAtm)));
bs = params.Bs * onesGrid; 
bse = params.Bse * onesGrid; 
bst = params.Bst * onesGrid;
bg = params.Bg * onesGrid;
ext = params.ExH * pre.basin.harvested; % harvest = 1 in places that are harvested, 0 everywhere else
fg = params.F * pre.basin.recharge; 
rdn = params.Rdn * onesGrid;
rbio = params.Rbio * onesGrid;
tsettl = params.Tsettl * onesGrid;
% lacus = params.Lacus * onesGrid;
fstor = params.Fstor .* (1 - pre.basin.recharge); %assume 0 net deep storage in highest recharge cells
sevent = params.Sevent .* pre.basin.Sevent;
gevent = params.Gevent .* pre.basin.Gevent; 
sef = params.SepEff .* onesGrid;

% Initialize output variables
numsheds = length(pre.watershed.watershedList);
sim = zeros(numsheds,1);
if pre.mapOption
    outMaps = struct();
else
    outMaps = [];
end
if pre.legacyOption
    outDistrib = struct('groundwater',zeros(max(pre.basin.gwtt(:)),numsheds),...
        'surfacewater',zeros([1,numsheds]));
else
    outDistrib = [];
end
if pre.sourceOption
    % Finally, initialize the watershed-level table for source-specific
    % deliveries
    tableSources = pre.obs;
    zerosArray = zeros(size(pre.obs.flow));
    
    % Surfacewater-delivered
    tableSources.delQatmSurf = zerosArray;
    tableSources.delQAgCommSurf = zerosArray;
    tableSources.delQManSurf = zerosArray;
    tableSources.delQNonAgSurf = zerosArray;
    tableSources.delQFixSurf = zerosArray;
 
    % Groundwater-delivered
    tableSources.delQatmGround = zerosArray;
    tableSources.delQAgCommGround = zerosArray;
    tableSources.delQManGround = zerosArray;
    tableSources.delQNonAgGround = zerosArray;
    tableSources.delQFixGround = zerosArray;
    
    tableSources.delQSepGround = zerosArray;
    
    % Point sources 
    tableSources.delQPoint = zerosArray;    
else
    tableSources = [];
end

%% Model-wide calculations of deliveries to stream, including basin-reduction terms
% Save a bunch of calculation and do the applied/mobile nutrients once for
% the whole region
% Then, calculate the basin-reduction terms
flowLen = pre.basin.flowlenOverland; % for convenience
Bs = exp(-flowLen .* bs);
Bg = exp(-flowLen .* bg);
Bse = exp(-flowLen .* bse);

% Handle tile drainage
indTile = pre.basin.tiles;
Bs(indTile) = exp(-flowLen(indTile) .* bst(indTile)); 

% Calculate the mobile components of applied nutrients along each pathway
% surfApply = pre.sources.QAtm + pre.sources.QAgComm + pre.sources.QMan + pre.sources.QNonAg + pre.sources.QFix;
% sepApply = pre.sources.QSep;
% pointApply = pre.sources.QSep;
cropHarvest = ext .* (pre.sources.QAtm + pre.sources.QAgComm + pre.sources.QMan + pre.sources.QNonAg + pre.sources.QFix); % for convenience/clarity
surfAvail = (1 - ext) .* (pre.sources.QAtm + pre.sources.QAgComm + pre.sources.QMan + pre.sources.QNonAg + pre.sources.QFix); % for convenience/clarity
surfMobile = double(sevent) .* (1 - fg) .* surfAvail;
groundAvail = fg .* surfAvail;
soilStore = fstor .* groundAvail;
groundMobile = double(gevent) .* (groundAvail - soilStore); % equaivalent to: fg .* (1 - fstor) .* surfAvail;
sepMobile = double(gevent) .* (1 - sef) .* pre.sources.QSep;

% Multiply mobile nutrients by basin-reduction terms
overlandBasin = Bs .* surfMobile;
groundBasin = Bg .* groundMobile;
sepBasin = Bse .* sepMobile;

%% Output options
% If the user wants source-specific deliveries, do this also
if pre.sourceOption
    % Surface-water pathway, surface-applied nutrients
    surfMobFrac = double(sevent) .* (1 - ext) .* (1 - fg);
    surfMobileQAtm = surfMobFrac .* pre.sources.QAtm;
    surfMobileQAgComm = surfMobFrac .* pre.sources.QAgComm;
    surfMobileQMan = surfMobFrac .* pre.sources.QMan;
    surfMobileQNonAg = surfMobFrac .* pre.sources.QNonAg;
    surfMobileQFix = surfMobFrac .* pre.sources.QFix;
    
    % Groundwater pathway, surface-applied nutrients
    groundMobFracSurf = (1 - ext) .* fg .* (1 - fstor) .* double(gevent);
    groundMobileQAtm = groundMobFracSurf .* pre.sources.QAtm;
    groundMobileQAgComm = groundMobFracSurf .* pre.sources.QAgComm;
    groundMobileQMan = groundMobFracSurf .* pre.sources.QMan;
    groundMobileQNonAg = groundMobFracSurf .* pre.sources.QNonAg;
    groundMobileQFix = groundMobFracSurf .* pre.sources.QFix; 
    
    % Groundwater pathway, subsurf-applied nutrients
    groundMobileQSep = (1 - sef) .* double(gevent) .* pre.sources.QSep;
    
    % Multiply each by the basin-reduction terms
    basinSurfQAtm = Bs .* surfMobileQAtm;
    basinSurfQAgComm = Bs .* surfMobileQAgComm;
    basinSurfQMan = Bs .* surfMobileQMan;
    basinSurfQNonAg = Bs .* surfMobileQNonAg;
    basinSurfQFix = Bs .* surfMobileQFix;
    
    basinGroundQAtm = Bg .* groundMobileQAtm;
    basinGroundQAgComm = Bg .* groundMobileQAgComm;
    basinGroundQMan = Bg .* groundMobileQMan;
    basinGroundQNonAg = Bg .* groundMobileQNonAg;
    basinGroundQFix = Bg .* groundMobileQFix;
    
    basinGroundQSep = Bse .* groundMobileQSep;
end

%% Watershed loop
% Loop through watersheds calculating loads/concentrations
if progress, h = waitbar(0,'Looping through watersheds'); end
for m = 1:numsheds  %1:1
    if progress, waitbar(m/numsheds,h); end
    thisShed = pre.watershed.watersheds{m};
   
    % Get the in-stream reduction parameter for this watershed
    R = exp((-pre.watershed.DNsorption{m} .* rdn(thisShed))).* exp((-pre.watershed.timeInstream{m} .* rbio(thisShed))); 
    % DNsorption as the factor for denitrification or P sorption
    % timeInstream as the factor for Biological uptake and Burial 
       
    % R = exp((-pre.watershed.timeInstream{m} .* r(thisShed))).* (min(1,(params.BY .* pre.obs.BY(m))));  
    % R = exp((-pre.watershed.timeInstream{m} .* r(thisShed))).* pre.obs.BY(m);
    % R = exp((-pre.watershed.timeInstream{m} .* r(thisShed))).* params.BY .* pre.obs.BY(m);  

    % Handle lakes  
    Tsettl = exp(-pre.watershed.TsettlingLake{m} .* tsettl(thisShed));
    %% Lacus = exp(-pre.watershed.Flowlenlac{m} .* lacus(thisShed));
    
    %Calculate each component of the load delivered to the stream outlet
    overlandDelivered = Tsettl .* R .* overlandBasin(thisShed); % Lacus
    groundDelivered = Tsettl .* R .* groundBasin(thisShed);
    sepDelivered = Tsettl .* R .* sepBasin(thisShed);
    pointDelivered = Tsettl .* R .* pre.sources.QPoint(thisShed);
    
    %Calculate the net loadDelivered
    loadDelivered = overlandDelivered + groundDelivered + sepDelivered + pointDelivered;
    
    %calculate the 
    %Sum Load for Watersheds, calculate concentration or load, depending on the option
    sim(m) = sum(loadDelivered);
    if pre.concOption
        sim(m) = sim(m)/pre.obs.flow(m);
    end
    
    %% Output options within the watershed loop
    if pre.sourceOption % Calculate river reduction for each source
        delSurfQAtm =  Tsettl .* R.* basinSurfQAtm(thisShed);
        delSurfQAgComm =  Tsettl .* R.* basinSurfQAgComm(thisShed);
        delSurfQMan  =  Tsettl .* R.* basinSurfQMan(thisShed);
        delSurfQNonAg =  Tsettl .* R.* basinSurfQNonAg(thisShed);
        delSurfQFix =  Tsettl .* R.* basinSurfQFix(thisShed);
        
        delGroundQAtm =  Tsettl .* R .* basinGroundQAtm(thisShed);
        delGroundQAgComm =  Tsettl .* R .* basinGroundQAgComm(thisShed);
        delGroundQMan =  Tsettl .* R .* basinGroundQMan(thisShed);
        delGroundQNonAg =  Tsettl .* R .* basinGroundQNonAg(thisShed);
        delGroundQFix =  Tsettl .* R .* basinGroundQFix(thisShed);
        
        delGroundQSep =  Tsettl .* R .* basinGroundQSep(thisShed);
        
        delQPoint = pointDelivered;
        
        % Summarize for the output table
        tableSources.delQatmSurf(m) = sum(delSurfQAtm);
        tableSources.delQAgCommSurf(m) = sum(delSurfQAgComm);
        tableSources.delQManSurf(m) = sum(delSurfQMan);
        tableSources.delQNonAgSurf(m) = sum(delSurfQNonAg);
        tableSources.delQFixSurf(m) = sum(delSurfQFix);
        
        % Groundwater-delivered
        tableSources.delQatmGround(m) = sum(delGroundQAtm);
        tableSources.delQAgCommGround(m) = sum(delGroundQAgComm);
        tableSources.delQManGround(m) = sum(delGroundQMan);
        tableSources.delQNonAgGround(m) = sum(delGroundQNonAg);
        tableSources.delQFixGround(m) = sum(delGroundQFix);
        
        tableSources.delQSepGround(m) = sum(delGroundQSep);
        
        % Point sources
        tableSources.delQPoint(m) = sum(delQPoint);
    end
    
    if pre.legacyOption
        %Calculate the weighted histogram of gwtt-delayed deliveries
        totalGround = groundDelivered + sepDelivered;
        weightedHistogram = accumarray(pre.basin.gwtt(thisShed),totalGround);
        weightedHistogram(isnan(weightedHistogram)) = 0;
        outDistrib.groundwater((1:length(weightedHistogram)),m) = weightedHistogram;
        outDistrib.surfacewater(m) = sum(overlandDelivered + pointDelivered);
    end
    
end
if progress, if ishandle(h);close(h);end, end

%% Map output
% Create output maps, if requested
if pre.mapOption

    % Total applied
    outMaps.appTotal = pre.sources.QAtm + pre.sources.QAgComm + pre.sources.QMan + ...
        pre.sources.QNonAg + pre.sources.QFix + pre.sources.QSep + pre.sources.QPoint;
    
%     % surface applied 
%     outMaps.appsurf = pre.sources.QAtm + pre.sources.QAgComm + pre.sources.QMan + pre.sources.QNonAg + pre.sources.QFix;
%     
%     % Septic tanks applied 
%     outMaps.appsep = pre.sources.QSep;
%     
%     % Point sorces applied 
%     outMaps.apppoint =  pre.sources.QPoint;

    % crop harvest 
	outMaps.cropHarvest = cropHarvest;
	
%     % surfAvail
%     outMaps.surfAvail = surfAvail;
%     
%     % surfMobile
%     outMaps.surfMobile = surfMobile;
%     
    % groundAvail
    outMaps.groundAvail = groundAvail;
    
    % Soil stored nutrients 
    outMaps.soilStore = soilStore;
    
%     % Ground mobile nutrients 
%     outMaps.groundMobile = groundMobile;
%     
%     % Source specific ground mobile nutrients
%     outMaps.groundMobileQAtm = groundMobileQAtm;
%     outMaps.groundMobileQAgComm = groundMobileQAgComm;
%     outMaps.groundMobileQMan = groundMobileQMan;
%     outMaps.groundMobileQNonAg = groundMobileQNonAg;
%     outMaps.groundMobileQFix = groundMobileQFix;
%     outMaps.groundMobileQSep = groundMobileQSep;
%   
%     % Groundwater pathway, subsurf-applied nutrients
%     outMaps.SepMobile = sepMobile; 
%    
    % Get the load delivered to streams 
    outMaps.Overland2river = overlandBasin; 
    outMaps.ground2river = groundBasin;
    outMaps.sep2river = sepBasin;
    outMaps.point2river = pre.sources.QPoint;
   
    % Get basin loss 
    outMaps.overlandBasinLoss = surfMobile - overlandBasin; % or (1-Bs).* surfMobile
    outMaps.groundBasinLoss = groundMobile - groundBasin; % or (1-Bg).* groundMobile
    outMaps.sepBasinLoss = sepMobile - sepBasin;  % or (1-Bse).* sepMobile
    outMaps.totalBasinLoss = outMaps.overlandBasinLoss + outMaps.groundBasinLoss + outMaps.sepBasinLoss;
    
    % Get the region-wide river-survival parameter
    R = exp((-pre.basin.DNsorption .* rdn)).* exp((-pre.basin.timeInstream .* rbio)); 
    % R = exp(-pre.basin.timeInstream .* rt).* exp(-pre.basin.lengthInstream .* rd).* (min(1,params.BY * pre.basin.BY)); 
    % R = exp(-pre.basin.timeInstream .* rt).* exp(-pre.basin.lengthInstream .* rd); 
    % R = exp(-pre.basin.timeInstream .* r).* (min(1,params.BY * pre.basin.BY)); 
    % R = exp(-pre.basin.timeInstream .* r).* params.BY * pre.basin.BY;  
   
    Tsettl = exp(-pre.basin.TsettlingLake.* tsettl);
    %% Lacus = exp(-pre.basin.Flowlenlac.* lacus);
  
    % Calculate each component of the load delivered 
    outMaps.overlandDelivered = Tsettl .* R .* overlandBasin;
    outMaps.groundDelivered =  Tsettl .* R .* groundBasin;
    outMaps.sepDelivered = Tsettl .* R .* sepBasin;
    outMaps.pointDelivered = Tsettl .* R .* pre.sources.QPoint;
    
%     % calculate the load delivered for surface water and groundwater 
%     outMaps.surfDelivered = outMaps.overlandDelivered + outMaps.pointDelivered;
%     outMaps.gwDelivered = outMaps.groundDelivered + outMaps.sepDelivered;
 
    % Summarize to get total deliveries
    outMaps.delTotal = outMaps.overlandDelivered + outMaps.groundDelivered + outMaps.sepDelivered + outMaps.pointDelivered;
  
    % map net R layer and river reduction nutrients 
    outMaps.R =  Tsettl .* R;
    outMaps.riverUptake = outMaps.Overland2river + outMaps.ground2river + outMaps.sep2river +  outMaps.point2river - outMaps.delTotal;

    % map by combo 
    % outMaps.BYcombo = params.BY * pre.basin.BY;
    
    % Do source-specific maps
    if pre.sourceOption
        % Calculate deliveries maps
        outMaps.delSurfQAtm =  Tsettl .* R .* basinSurfQAtm;
        outMaps.delSurfQAgComm =  Tsettl .* R .* basinSurfQAgComm;
        outMaps.delSurfQMan =  Tsettl .* R .* basinSurfQMan;
        outMaps.delSurfQNonAg =  Tsettl .* R .* basinSurfQNonAg;
        outMaps.delSurfQFix =  Tsettl .* R .* basinSurfQFix;
        
        outMaps.delGroundQAtm =  Tsettl .* R .* basinGroundQAtm;
        outMaps.delGroundQAgComm =  Tsettl .* R .* basinGroundQAgComm;
        outMaps.delGroundQMan =  Tsettl .* R .* basinGroundQMan;
        outMaps.delGroundQNonAg =  Tsettl .* R .* basinGroundQNonAg;
        outMaps.delGroundQFix =  Tsettl .* R .* basinGroundQFix;
        
        outMaps.delGroundQSep =  Tsettl .* R .* basinGroundQSep;
        
        outMaps.delQPoint =  Tsettl .* R .* pre.sources.QPoint;
       
    end
    
end

% Finally, prepare additional outputs
if nargout > 1
    addOutput = struct('maps',outMaps,'legacy',outDistrib,'sourceTable',tableSources);
end
