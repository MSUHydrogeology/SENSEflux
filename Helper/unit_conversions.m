function [output] = unit_conversions(input,varargin)
%UNIT_CONVERSIONS  Convert units quickly and with an easily extensible database.
%   [output] = unit_conversions(input,varargin)
%
%   To add new conversion types, modify the code below by specifying:
%   'unit',[factor,offset].  The factor and offset values are applied as
%   follows: SI_unit =  (input  +  offset)*factor; Please add both the the
%   list in the next section, and in the structured table within the code.
%
%   Currently supported units: (replace any slashes with the letter 'p')
%   concentration: ug/L, mg/L, kg/m^3
%   velocity: kts, m/s, mi/h, mm/hr, m/day, ft/s
%   areal flux: mm/yr, m/yr
%   length: ft, in, mm, mi, cm, m, km
%   area: ft2, in2, mm2, mi2, cm2, m2, km2, acre, ha
%   volume: ft3, in3, mm3, mi3, cm3, m3, km3, acreft, gal, mgal, oz
%   temperature: F, C, K, R
%   delta temperature: delF, delC, delK, delR
%   pressures: mbar, bar, Pa, inHg, mmHg, hPa, atm
%   energy: kJ, J, MJ, cal, kcal, erg, kWh, eV, btu
%   angles: deg, rad, az
%   times: s, min, hr, day, sidday, week, yr, leapyr, sidyr, julyr, gregyr, tropyr
%   time rates: ps, pmin, phr, pday, pweek
%   time zones: EST, EDT, UTC <--where one day equals one unit
%   percentages: pcent, pmil, dec
%   volumetric fluxes: cfs, cms, Mgd, gpm
%
%   Notes on time units: yr = common year (365 days), leapyr = leap year
%   (366 days), tropyear = tropical year (365.242198781 days), julyr =
%   julian year (365.25 days), gregyr = gregorian year (365.2425 day),
%   sidyr = sidereal year (31558149.540), sidday = sidereal day
%   (86164.09053)
%
%   Descriptions of Input Variables:
%   input: an input numeric, cell, or structure array all in the same units
%   varargin: either a string specifying the current units (see table), in
%       which case the output will be in standard units.  Otherwise, two
%       strings representing the input units (first) and the output units
%       (second).  Consistency of units is NOT checked!
%
%   Descriptions of Output Variables:
%   output: output of the same class as the input, with units converted if
%       possible.
%
%   Example(s):
%   >> tempK = unit_conversions(airTemp,'C','K'); %will output air
%   temperature from degrees C to degrees K
%   >> airPress = unit_conversions(airPress,'mmHg'); %will output the air
%   pressure in the standard units, (Pa).
%
%   See also:

% Author: Anthony Kendall
% Contact: anthony [dot] kendall [at] gmail [dot] com
% Created: 2008-03-11
% Copyright 2008 Michigan State University.

%Check to see if input units are specified, throw an error if not
% assert_ILHM(nargin > 1, 'Both input values and units must be specified');

%define conversion table
table = struct('ugl',[1e-6,0],'mgl',[1e-3,0],'kgm3',[1,0],... %concentration group
	'kts',[0.514444,0],'mps',[1,0],'miph',[0.44704,0],'mmphr',[(3.6e6)^-1,0],'mpday',[1/86400,0],'ftps',[0.3048,0],... %velocity group
    'mpyr',[1/(86400*365.242198781),0],'mmpyr',[1/(1000*(86400*365.242198781)),0],...
    'ft',[0.3048,0],'in',[0.0254,0],'mi',[1609.34,0],'mm',[0.001,0],'cm',[0.01,0],'km',[1000,0],'m',[1,0],... %length group
    'ft2',[0.3048^2,0],'mi2',[1609.34^2,0],'km2',[1000^2,0],'m2',[1,0],'acre',[4046.86,0],'ha',[100^2,0],... %area group
    'ft3',[0.3048^3,0],'in3',[1/61023.7,0],'mi3',[1609.34^3,0],'km3',[1000^3,0],'m3',[1,0],'acreft',[1233.48,0],... %volume group
    'gal',[1/264.1721,0],'Mgal',[1/(264.1721*10^-6),0],'oz',[1/33814,0],... %volume group cont.
    'F',[5/9,-32],'C',[1,0],'K',[1,-273.15],'R',[5/9,-491.67],... %temperature group
    'delF',[5/9,0],'delC',[1,0],'delK',[1,0],'delR',[5/9,0],... %delta temperature group
    'mbar',[100,0],'bar',[1e5,0],'Pa',[1,0],'inHg',[3386.39,0],'mmHg',[133.322,0],'hPa',[100,0],'atm',[101325,0],... %pressure group
    'kJ',[1000,0],'J',[1,0],'MJ',[1e6,0],'cal',[4.1868,0],'kcal',[4186.8,0],'erg',[1e-7,0],'eV',[1.60218e-19,0],'kWh',[3.6e6,0],'btu',[1055.06,0],... %energy group
    'deg',[2 * pi()/360,0],'rad',[1,0],'az',[-2*pi()/360,-90],... %angular units group
    's',[1,0],'min',[60,0],'hr',[3600,0],'day',[86400,0],'week',[86400*7,0],... 
    'yr',[86400*365,0],'leapyr',[86400*366,0],'tropyr',[86400*365.242198781,0],...
    'julyr',[86400*365.25,0],'gregyr',[86400*365.2425,0],'sidyr',[31558149.540,0],...
    'sidday',[86164.09053,0],...%time group
    'ps',[1,0],'pmin',[1/60,0],'phr',[1/3600,0],'pday',[1/86400,0],'pweek',[1/(86400*7),0],'pyr',[1/(86400*365),0],... %time rate group
    'EST',[1,5/24],'EDT',[1,4/24],'UTC',[1,0],... %time zones group
    'pcent',[1/100,0],'pmil',[1/1000,0],'dec',[1,0],... %percentages group
    'cms',[1,0],'cfs',[0.3048^3,0],'Mgd',[0.043813,0],'gpm',[0.000063,0]); %volumetric fluxes

%go through the inputs and convert their units
if isnumeric(input) || islogical(input)
    output = numeric_convert(input,table,varargin);
elseif isstruct(input)
    output = struct_convert(input,table,varargin);
elseif iscell(input)
    output = cell_convert(input,table,varargin);
else
    warning('This function only supports arrays of type cell, struct, or numeric')
    output = input;
end
end

function [output] = struct_convert(input,table,unit_args)
fields = fieldnames(input);
output = input;
for m = 1:length(fields)
    if isnumeric(input.(fields{m}))
        output.(fields{m}) = numeric_convert(input.(fields{m}),table,unit_args);
    elseif isstruct(input.(fields{m}))
        output.(fields{m}) = struct_convert(input.(fields{m}),table,unit_args);
    elseif iscell(input.(fields{m}))
        output.(fields{m}) = cell_convert(input.(fields{m}),table,unit_args);
    else %must be an unsupported data type
       warning('This function only supports arrays of type cell, struct, numeric, or logical')
       output.(fields{m}) = input.(fields{m});
    end
end
end

function [output] = cell_convert(input,table,unit_args)
output = input;
for m = 1:numel(input)
    if iscell(input{m})
        output{m} = cell_convert(input{m},table,unit_args);
    elseif isnumeric(input{m})
        output{m} = numeric_convert(input{m},table,unit_args);
    else %must be an unsupported data type
        warning('This function only supports arrays of type cell, struct, numeric, or logical')
        output{m} = input{m};
    end
end
end

function [output] = numeric_convert(input,table,unit_args)
input_units = unit_args{1};
intermed = (input + table.(input_units)(2)) * table.(input_units)(1);
if (length(unit_args) == 2)
    output_units = unit_args{2};
    output = intermed / table.(output_units)(1) - table.(output_units)(2);
else
    output = intermed;
end
end