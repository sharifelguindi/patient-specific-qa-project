%--------------------------------------------------------------------------
% READMAPCHECK read MapCheck text file
% MAPCHECKARRAY=READMAPCHECK(FILEPATH,FILENAME) reads the MapCheck output 
% text file specified by FILEPATH and FILENAME and stores it in the
% MAPCHECKARRAY structure array. 
%--------------------------------------------------------------------------
function [mapCheckArray,headerInfo, headerText] = readMapCheck(filename)


%% Initialization
%--------------------------------------------------------------------------
% Initialize Output Variables
%--------------------------------------------------------------------------
headerInfo    = [];
mapCheckArray = [];


%% Open File
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------
fileID = fopen(filename);
C = textscan(fileID,'%s','delimiter','\n');
for i = 1:length(C{1}) 
    if strcmp(C{1}(i),'Background') == 1; 
           numHeaderRows = i + 1; 
    end
end
fclose(fileID);

fileID = fopen(filename);

%% Read File
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------

% Part 1: Read Header Information
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------

numInterDataRows = 5;     % Hard-coded expectation of # of inter-data rows
numDataBlocks    = 7;     % Hard-coded expectation of # of data blocks
headerTextCell   = textscan(fileID,'%s',numHeaderRows,'delimiter','\n');
headerText       = char(headerTextCell{1});

%--------------------------------------------------------------------------
% Make Header Structure
%--------------------------------------------------------------------------
[L , ~] = size(headerText);
headerInfo = convertMapCheckHeader(headerText, L);

%--------------------------------------------------------------------------
% Read Data Blocks
%--------------------------------------------------------------------------

formatString  = repmat('%f',1,headerInfo.numCols+2);

for ii = 1:numDataBlocks   
    dataBlockCell     = textscan(fileID,formatString,'delimiter',' ');
    dataBlock(:,:,ii) = cell2mat(dataBlockCell);
    interDataText     = textscan(fileID,'%s',numInterDataRows,'delimiter','\n');
end

%% Do Some Additional Processing Here (in the future)
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------
mapCheckArray = dataBlock;

%% Close File
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------
fclose(fileID);