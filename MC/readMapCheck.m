%--------------------------------------------------------------------------
% READMAPCHECK read MapCheck text file
% MAPCHECKARRAY=READMAPCHECK(FILEPATH,FILENAME) reads the MapCheck output 
% text file specified by FILEPATH and FILENAME and stores it in the
% MAPCHECKARRAY structure array. 
%--------------------------------------------------------------------------
function [M_total, mapCheckArray, headerInfo, interDataText] = readMapCheck(filename)


%% Initialization
%--------------------------------------------------------------------------
% Initialize Output Variables
%--------------------------------------------------------------------------
headerInfo    = [];
mapCheckArray = [];


%% Determine Header Ending by number of header rows (numHeaderRows)
%--------------------------------------------------------------------------
% Variable header depending on type of mapcheck file
%--------------------------------------------------------------------------
fileID = fopen(filename);
C = textscan(fileID,'%s','delimiter','\n');
for i = 1:length(C{1}) 
    if strcmp(C{1}(i),'Background') == 1; 
           numHeaderRows = i + 1; 
    end
end
fclose(fileID);

%% Open File
%--------------------------------------------------------------------------
% User standard fopen (text file)
%--------------------------------------------------------------------------
fileID = fopen(filename);

%% Read File
%--------------------------------------------------------------------------
% Load each section of MapCheck file to dataBlock Array
%--------------------------------------------------------------------------

% Part 1: Read Header Information
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------

headerTextCell   = textscan(fileID,'%s',numHeaderRows,'delimiter','\n');
headerText       = char(headerTextCell{1});

%--------------------------------------------------------------------------
% Make Header Structure
%--------------------------------------------------------------------------
[L , ~]    = size(headerText);
headerInfo = convertMapCheckHeader(headerText, L);

%--------------------------------------------------------------------------
% Read Data Blocks
%--------------------------------------------------------------------------

numInterDataRows = 5;     % Hard-coded expectation of # of inter-data rows
numDataBlocks    = 9;     % Hard-coded expectation of # of data blocks
formatString     = repmat('%f',1,headerInfo.numCols+2);

for ii = 1:numDataBlocks   
    dataBlockCell       = textscan(fileID,formatString,'delimiter',' ');
    dataBlock(:,:,ii)   = cell2mat(dataBlockCell);
    interDataText(ii,:) = textscan(fileID,'%s',numInterDataRows,'delimiter','\n'); %#ok<*AGROW>
end


%% Reshape Dose Measured Matrix
%--------------------------------------------------------------------------
% Store dataBlock in mapCheckArray; Convert Dose Counts (measured) to
% 341x281 matric at 1 mm spacing for gamma analysis computations
%--------------------------------------------------------------------------

mapCheckArray = dataBlock;

Dose_Counts = 6;
M             = mapCheckArray(:,3:end,Dose_Counts);
col_value     = strsplit(interDataText{Dose_Counts, 1}{2, 1},'\t');
col_value     = str2double(col_value(2:end));
row_value     = mapCheckArray(:,1,7);
col_resize    = transpose((-14.1:0.1:14));
row_resize    = transpose((17.1:-0.1:-17));

M_total        = zeros(length(row_resize),length(col_resize));
M_total(1,:)   = col_resize;
M_total(:,1)   = row_resize;

[ix]       = find(roundn(M_total(:,1),-2) == row_value(end));
M_finish_x = ix;
[iy]       = find(roundn(M_total(1,:),-2) == col_value(end));
M_finish_y = iy;

[ix]       = find(roundn(M_total(:,1),-2) == row_value(1));
M_start_x  = ix;
[iy]       = find(roundn(M_total(1,:),-2) == col_value(1));
M_start_y  = iy;

M_total(M_start_x:5:M_finish_x,M_start_y:5:M_finish_y) = M;

%% Close File
%--------------------------------------------------------------------------
% Close file for future use
%--------------------------------------------------------------------------
fclose(fileID);