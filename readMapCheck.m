%--------------------------------------------------------------------------
% READMAPCHECK read MapCheck text file
% MAPCHECKARRAY=READMAPCHECK(FILEPATH,FILENAME) reads the MapCheck output 
% text file specified by FILEPATH and FILENAME and stores it in the
% MAPCHECKARRAY structure array. If no filepath or filename are specified,
% the function will provide a GUI explorer window (for Windows machines
% only) to search for the correct file.
%--------------------------------------------------------------------------
function [mapCheckArray,headerInfo] = readMapCheck(filename)


%% Initialization
%--------------------------------------------------------------------------
% Initialize Output Variables
%--------------------------------------------------------------------------
headerInfo    = [];
mapCheckArray = [];

% %% MapCheck File Determination
% %--------------------------------------------------------------------------
% % Explanation here...
% %--------------------------------------------------------------------------
% switch nargin
%     
%     case 2
%         filePath = varargin{1};
%         fileName = varargin{2};
%         
%         % Check that filePath terminates in correct file separation character
%         if ~strcmp(filePath(end),filesep)
%             filePath = [filePath filesep];
%         end
%         
%     case 1
%         filePath = varargin{1};
%         
%         % Check that filePath terminates in correct file separation character
%         if ~strcmp(filePath(end),filesep)
%             filePath = [filePath filesep];
%         end
%         
%         [fileName,filePath] = uigetfile([filePath '*.txt'], 'Please select MapCHECK file');
%     case 0
%         [fileName,filePath] = uigetfile('*.txt', 'Please select MapCHECK file');
% 
%     otherwise
%          error('Too many input arguments');
% end
% 
% % Check that filePath terminates in correct file separation character
% if ~strcmp(filePath(end),filesep)
%     filePath = [filePath filesep];
% end

%% Open File
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------
fileID = fopen(filename);


%% Read File
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------

% Part 1: Read Header Information
%--------------------------------------------------------------------------
% Explanation here...
%--------------------------------------------------------------------------
numHeaderRows    = 45;    % Hard-coded expectation of # of rows in header
numInterDataRows = 5;     % Hard-coded expectation of # of inter-data rows
numDataBlocks    = 7;     % Hard-coded expectation of # of data blocks

headerTextCell   = textscan(fileID,'%s',numHeaderRows,'delimiter','\n');
headerText       = char(headerTextCell{1});

%--------------------------------------------------------------------------
% Make Header Structure
%--------------------------------------------------------------------------
headerInfo = convertMapCheckHeader(headerText);
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