function [varargout] = extend_domain(structIndices,varargin)
%EXTEND_DOMAIN  Reverses the "trim_domain" process and returns original size array.
%   varargout = extend_domain(structIndices,varargin)
%
%   Descriptions of Input Variables:
%   structIndices: lookup table structure produced by "trim_domain"
%   varargin: an arbitrary length assortment of numeric, logical, cell, or
%       structured arrays.  Types can be mixed: i.e. a structured array can
%       have cell and numeric sub-components, and the tree can be of arbitrary
%       depth.  The numeric structure is a bit more strict, as it assumes that
%       the size of the arrays make sense within ILHM.
%
%   Descriptions of Output Variables:
%   varargout: the extended version of each array in varargin is returned.
%
%   Example(s):
%   >> [fullET,fullRecharge] = extend_domain(structIndices, partET,
%   partRecharge);
%
%   See also: trim_domain

% Author: Anthony Kendall
% Contact: anthony [dot] kendall [at] gmail [dot] com
% Created: 2008-03-11
% Copyright 2008 Michigan State University.

assert(isstruct(structIndices),'First input must be the indices structured array output by trim_domain');

modelIndices = structIndices.indices;
origSize = structIndices.origSize;
trimSize = structIndices.trimSize;

for m = 1:length(varargin)
    input = varargin{m};
    if isnumeric(input) || islogical(input)
        output = numeric_extend(input,modelIndices,origSize,trimSize);
    elseif isstruct(input)
        output = struct_extend(input,modelIndices,origSize,trimSize);
    elseif iscell(input)
        output = cell_extend(input,modelIndices,origSize,trimSize);
    else
%         warning_ILHM('This function only supports arrays of type cell, struct, numeric, or logical')
        output = input;
    end
    varargout{m} = output;
end

end

function [output] = struct_extend(input,modelIndices,origSize,trimSize)
fields = fieldnames(input);
output = input;
for m = 1:length(fields)
    if isstruct(input.(fields{m}))
        output.(fields{m}) = struct_extend(input.(fields{m}),modelIndices,origSize,trimSize);
    elseif iscell(input.(fields{m}))
        output.(fields{m}) = cell_extend(input.(fields{m}),modelIndices,origSize,trimSize);
    elseif isnumeric(input.(fields{m})) || islogical(input.(fields{m}))
        output.(fields{m}) = numeric_extend(input.(fields{m}),modelIndices,origSize,trimSize);
    else %must be an unsupported data type
%         warning_ILHM('This function only supports arrays of type cell, struct, numeric, or logical')
        output.(fields{m}) = input.(fields{m});
    end
end
end

function [output] = cell_extend(input,modelIndices,origSize,trimSize)
output = input;
for m = 1:numel(input)
    if iscell(input{m})
        output{m} = cell_extend(input{m},modelIndices,origSize,trimSize);
    elseif isnumeric(input{m}) || islogical(input{m})
        output{m} = numeric_extend(input{m},modelIndices,origSize,trimSize);
    else %must be an unsupported data type
%         warning_ILHM('This function only supports arrays of type cell, struct, numeric, or logical')
        output{m} = input{m};
    end
end
end

function [output] = numeric_extend(input,modelIndices,origSize,trimSize)
if (size(input,1) == trimSize) 
    numRow = origSize(1);
    numCol = origSize(2);
    numLay = size(input,2);
    if (numCol == 1) && (numLay > 1)
        if isnumeric(input)
            output = zeros([numRow,numLay],class(input));
        else
            output = false([numRow,numCol]);
        end
        for n = 1:numLay
            output(modelIndices,n) = input(:,n);
        end
    elseif numLay == 1
        if isnumeric(input)
            output = zeros([numRow,numCol],class(input));
        else
            output = false([numRow,numCol]);
        end
        output(modelIndices) = input;
    else
        if isnumeric(input)
            output = zeros([numRow,numCol,numLay],class(input));
        else
            output = false([numRow,numCol]);
        end
        for n = 1:numLay
            output_temp = output(:,:,n);
            output_temp(modelIndices) = input(:,n);
            output(:,:,n) = output_temp;
        end
    end
else
%     warning_ILHM('Numeric or logical arrays not affected by trim_domain were left unmodified')
    output = input;
end
end