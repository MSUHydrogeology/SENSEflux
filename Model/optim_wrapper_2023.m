function [objTot,varargout] = optim_wrapper(alphas,varargin)
persistent outFile statFunc initData iterData

if nargin == 1
    runMode = 'optim';
elseif nargin == 2
    if ~isempty(varargin{1})
        runMode = lower(varargin{1});
    else
        runMode = 'optim';
    end
end

switch runMode
    case 'initialize'
        %Call the initialization function
        disp('Read in the input data')
        initData = cell(length(alphas),1); %alphas for initialize is actually a structured array with entries for each event
        for m = 1:length(alphas)
            initData{m} = alphas(m).initFunc(alphas(m));
        end
        %Save separately to variables
        statFunc = alphas(1).statFunc;
        outFile = alphas(1).outFile;
        %Initialize the iteration data array
        iterData = struct('iterNum',0,'minObj',100,'minAlphas',[]);
        %Return the initialization data
        objTot = NaN;
        varargout{1} = initData;
    case 'forward'
        % Run the model and get the simulated and observed values
        objTot = 0;
        [objInd,sim,addOutputs] = deal(cell(size(initData)));
        %[objInd] = cell(size(initData));
        for m = 1:length(initData)
            params = parse_params(alphas,initData{m},'forward');
            if initData{m}.sourceOption || initData{m}.mapOption || initData{m}.legacyOption
                [sim{m},addOutputs{m}] = statFunc(params,initData{m});
            else
                sim{m} = statFunc(params,initData{m});
            end
            [objInd{m}] = calc_obj_func(sim{m},initData{m});
            objTot = objTot + objInd{m};
        end
        
        % Create the output data table
        for m = 1:length(initData)
            thisTable = initData{m}.obs;
            thisTable.sim = sim{m};
            thisTable.event = repmat(m,height(thisTable),1); %assign a numerical event ID
            if m == 1
                outTable = thisTable;
                outTable.Properties.RowNames = string((1:height(outTable)));
            else
                thisTable.Properties.RowNames = string(height(outTable)+(1:height(thisTable))); % reset the index 
                outTable = cat(1,outTable,thisTable);  %1 mean row bind, 2 means column bind 
            end
        end
        varargout{1} = outTable;
        varargout{2} = addOutputs;
    case 'optim'
        %Calculate Objective
        objTot = 0;
        [objInd,sim] = deal(cell(size(initData)));
        for m = 1:length(initData)
            params = parse_params(alphas,initData{m},'optim');
            sim{m} = statFunc(params,initData{m});
            objInd{m} = calc_obj_func(sim{m},initData{m});
            objTot = objTot + objInd{m};
        end
        
        %Update the iterData array
        iterData.iterNum = iterData.iterNum + 1;
        if objTot < iterData.minObj
            iterData.minObj = objTot;
            iterData.minAlphas = alphas;
            disp(sprintf(['\nNew minimum objective value of %g on iteration %d. Alpha values were: \n','%g',repmat(', %g',1,length(alphas)-1)],...
                iterData.minObj,iterData.iterNum,iterData.minAlphas));
        end
        
        %Output this run
        fid = fopen(outFile,'at');
        fprintf(fid,[repmat('%g,',1,length(alphas)),repmat('%g,',1,length(objInd)),'%g\n'],alphas,objInd{:},objTot);
        fclose(fid);
        
        %Assign varargout
        varargout = objInd;
        
    otherwise
        error('Unrecongized run mode');
end
end

function params = parse_params(alphas,pre,mode)

% paramsList = {'F','ExH','Bs','Bs','Bst','R','R','Bg','Bse','BY','Fmobs','Fmobs','Fmobg','Fmobg','SepEff'};
% paramsList = {'F','ExH','Bs','Bst','R','Bg','Bse','BY'};
% paramsList = {'F','ExH','Bs','Bst','R','Bg','Bse','BY','Fmobs','Fmobg','SepEff'};
paramsList = {'F','ExH','Bs','Bst','Rdn','Rbio','Bg','Bse','SepEff','Fstor','Sevent','Gevent','Tsettl'}; % 'BY','','Lacus','Tsettl'
params = struct();


for m = 1:length(paramsList)
    thisParam = paramsList{m};
    
    % Set the parameter value
    switch lower(mode)
        case 'forward'
            params.(thisParam) = alphas(pre.alphasInd.(thisParam));
        case 'optim'
            if pre.alphasOptim.(thisParam)
                params.(thisParam) = alphas(pre.alphasIndOptim.(thisParam));
            else
                params.(thisParam) = pre.alphasInit.(thisParam);
            end
    end
    
    % Reverse log transform if needed
    if pre.alphasLog.(thisParam)
        params.(thisParam) = 10^params.(thisParam);
    end
end
end

% function [obj] = calc_obj_func(sim,pre)
% obs = pre.obs.obs(:);
% funcError = str2func(pre.errorFunc);
% %Calculate the objective function
% obj = funcError(sim(:),obs,pre); 
% end

function [obj] = calc_obj_func(sim,pre)
obs = pre.obs.obs(:);
% funcError = str2func(pre.errorFunc);
%Calculate the objective function
obj = error_mael(sim(:),obs); 
end

function obj = error_mael(sim,obs)
obj = mean(abs(log(sim)-log(obs)));
end

function obj = error_rmsl(sim,obs) 
obj = sqrt(mean(((log(sim) - log(obs)).^2)));
end

function obj = error_mae(sim,obs)
obj = mean(abs((sim)-(obs)));
end

function obj = error_rms(sim,obs)
obj = sqrt(mean(((sim - obs).^2)));
end

function obj = error_mape(sim,obs)
obj = mean(abs((sim-obs)./(obs)));
end




% function [obj] = calc_obj_func(sim,pre)
% obs = pre.obs.obs(:);
% % funcError = str2func(pre.errorFunc);
% %Calculate the objective function
% obj = error_rmsl(sim(:),obs,pre); 
% end
% 
% function obj = error_rms(sim,obs,pre)
% obj = sqrt(mean(((sim - obs).^2)));
% end
% 
% function obj = error_rmsl(sim,obs,pre) 
% obj = sqrt(mean(((log(sim) - log(obs)).^2)));
% end
% 
% function obj = error_mael(sim,obs,pre)
% obj = mean(abs(log(sim)-log(obs)));
% end
% 
% function obj = error_mape(sim,obs,pre)
% obj = mean(abs((sim-obs)./(obs)));
% end
% 
% function obj = error_mael_decluster(sim,obs,pre)
% distMetric = sqrt(pre.obs.nearDist./max(pre.obs.nearDist));
% obj = median(abs(log(sim)-log(obs)).*...
%     distMetric/mean(distMetric));
% end
% 
% function obj = error_mael_decluster_area(sim,obs,pre)
% distMetric = sqrt(pre.obs.nearDist./max(pre.obs.nearDist));
% areaMetric = sqrt(pre.obs.area./max(pre.obs.area));
% compMetric = distMetric .* areaMetric;
% obj = median(abs(log(sim)-log(obs)).*...
%     compMetric/mean(compMetric));
% end