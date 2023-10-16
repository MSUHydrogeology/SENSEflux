function [varargout] = import_grid(file,options)
%import_grid  Imports ARC grids into MATLAB format
%   [varargout] = import_grid(file,options)
%
%   This function is intended to be an interface that allows ILHM to be
%   developed independent of the particular interface used to read in ARC
%   grids.
%
%   Currently, it uses readgdal, a MEX file that accesses the GDAL library
%
%   Descriptions of Input Variables:
%   file:   a character array that defines the path and file of an ARC grid
%           that can be accessed by MATLAB.
%   options: a character array, or cell array.  Currently, the only options
%           are: 'header'.  'header' will read in just the header metadata,
%           and not the grid itself.
%
%   Descriptions of Output Variables:
%   varargout: If two outputs are requested without any specified options,
%           they will be: [grid,header].  If only one is specified, then it
%           will be [grid].  If an option is specified, then the outputs will
%           be modified.  The header information will have already been
%           converted into the format that ILHM recognizes.
%
%   Example(s):
%   >> [ibound,header] = import_grid(gridPath);
%   >> [header] = import_grid(gridPath,'header');
%   >> [ibound] = import_grid(gridPath);
%
%   See also:

% Author: Anthony Kendall
% Contact: anthony [dot] kendall [at] gmail [dot] com
% Created: 2008-09-23
% Copyright 2008 Michigan State University.

%Parse the input options
if nargin == 2
    if ischar(options)
        [optionsStr] = parse_options(options);
    elseif iscell(options)
        if length(options) == 1
            [optionsStr] = parse_options(options{1});
        else
            error('Currently, only one option string is supported')
        end
    else
        error('Options must be a character or cell array');
    end
    optionTest = true;
elseif nargin > 2
    error('Only two input arrays are allowed');
else
    optionTest = false;
end

%Read in the data, switching for the various options
[data,header] = gdalread(file);
header = gdal_header_parse(header);
header.nan = identify_nanval(class(data));

%Process the NaN values if it's float or double
[data,header] = replace_nanval(data,class(data),header);


if nargout == 2
    varargout{1} = data;
    varargout{2} = header;
elseif nargout ==1
    if optionTest
        varargout{1} = header;
    else
        varargout{1} = data;
    end
end

end

%Helper Functions
function [optionStr] = parse_options(inputStr)
switch lower(inputStr)
    case 'header'
        optionStr = '-M';
    otherwise
        error('Unrecognized input option');
end
end

function geoLoc = gdal_header_parse(gdalHeader)
geoLoc=struct('top',gdalHeader.GMT_hdr(4),'left',gdalHeader.GMT_hdr(1),...
    'bottom',gdalHeader.GMT_hdr(3),...
    'cellsizeX',gdalHeader.GeoTransform(2),'cellsizeY',-gdalHeader.GeoTransform(6),...
    'rows',gdalHeader.RasterYSize,'cols',gdalHeader.RasterXSize);

%If square cells
if geoLoc.cellsizeX == geoLoc.cellsizeY,geoLoc.cellsize = geoLoc.cellsizeX;end
end

function nanVal = identify_nanval(thisClass)
switch thisClass
    case {'uint8','uint16','uint32'}
        nanVal = double(intmax(thisClass));
    case {'int8','int16','int32'}
        nanVal = double(intmin(thisClass));
    otherwise
        nanVal = -realmax(thisClass);
end
end

function [data,header] = replace_nanval(data,thisClass,header)
switch thisClass
    case {'single','double'}
        testDiff = abs(data - header.nan);
        % Catch the easy cases
        testNan = testDiff == 0;
        data(testNan) = NaN;
        % Catch cases where floating point precision is a problem
        testNan = abs(1 - testDiff / abs(header.nan*eps(thisClass))) <= eps(thisClass);
        data(testNan) = NaN;
        header.nan = NaN;
    otherwise
        % integer grids don't get NaN assigned
end
end