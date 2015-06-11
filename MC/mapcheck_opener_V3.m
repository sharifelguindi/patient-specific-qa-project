function [ M_total ] = mapcheck_opener_V3( filename )

%               MapCheck FILE OPENER (1 or 2)
%               AUTHOR : SHARIF ELGUINDI, M.S.
%
% This program opens the dose file from a MapCheck 1 or MapCheck 2 txt file.
% This code is not optimized for speed, as it goes through 1 to many while
% loops, but it works well enough.  To use this file in matlab, you would
% type in the command window:

% Name_Of_Matrix_For_Output = mapcheck_opener('filename_to_open');

% The output files' first row and column give the position
% coordinates for the detectors and the rest of the matrix is the dose in a
% 1 mm grid.

% -----------------------------------------------------------------------
% Reads in file with space delimeter 
% -----------------------------------------------------------------------

fileID = fopen(filename);
C = textscan(fileID,'%s','delimiter','\n');
for i = 1:length(C{1}) 
    if strcmp(C{1}(i),'Background') == 1; 
           numHeaderRows = i + 1; 
    end
end
fclose(fileID);
% -----------------------------------------------------------------------
% These while loops determine the file type (mapcheck 1 or mapcheck 2)
% There is a space in the header of the txt file that outlines this.
% Sets variable "fileType" to 1 or 2.
% -----------------------------------------------------------------------


MC1 = '1175';
MC2 = '1177';

i = 1;

while i <= 30
    if strcmp(C{1}(i),MC1) == 1
        fileType = 1;
    end
    if strcmp(C{1}(i),MC2) == 1
        fileType = 2;
    end
    i = i + 1;
end

% -----------------------------------------------------------------------
% For the length of the string, find were "Dose Counts" starts
% This is the actual fully corrected dose found in the MapCheck File.
% -----------------------------------------------------------------------

start_name_1 = 'Dose';
start_name_2 = 'Counts';
finish_name = 'COL';

for i = 1:length(C{1})
    if strcmp(C{1}(i),start_name_1) == 1
        if strcmp(C{1}(i+1),start_name_2) == 1
            dose_count_start = i + 4;
        break;
        end
    end
end

i = i + 4;

while i <= length(C{1})
    if strcmp(C{1}(i),finish_name) == 1
        dose_count_end = i;
        break;
    end
    i = i + 1;
end


% -----------------------------------------------------------------------
% If MapCheck 1, arrange the string of characters into values for a matrix
% array that is 46 x 47 points in size.
% -----------------------------------------------------------------------

i = 1;
if fileType == 1

        M = zeros(46,47);

        for j = dose_count_start:47:dose_count_end

            M(i,1:47) = str2double(C{1}(j:j+46));
            i = i + 1;

        end

% -----------------------------------------------------------------------
% Keep the row and col postion values.  For Mapcheck 1 it goes from
% + 12cm to -12cm in 0.5 cm spacing.
% -----------------------------------------------------------------------

        row_value = M(1:end-1,1);
        col_value = transpose(M(1:end-1,1));
        M = M(1:45,3:end);

% -----------------------------------------------------------------------
% This last portion arranges the matrix into a much larger array with 1mm
% spacing.  This correlates to the output from the Pinnacle planning
% system, specific for UA Quality Assurance and is unneseccary.
% -----------------------------------------------------------------------
        col_resize = transpose((-12.1:0.1:12));
        row_resize = transpose((-12.1:0.1:12));
        M_total = zeros(length(row_resize),length(col_resize));
        M_total(1,:) = col_resize;
        M_total(:,1) = row_resize;

        [ix] = find(roundn(M_total(:,1),-2)==roundn(row_value(1),-2));
        M_finish_x = ix;
        [iy] = find(roundn(M_total(1,:),-2)==roundn(col_value(1),-2));
        M_finish_y = iy;

        [ix] = find(roundn(M_total(:,1),-2)==roundn(row_value(end),-2));
        M_start_x = ix;
        [iy] = find(roundn(M_total(1,:),-2)==roundn(col_value(end),-2));
        M_start_y = iy;

        M_total(M_start_x:5:M_finish_x,M_start_y:5:M_finish_y) = M;


% -----------------------------------------------------------------------
% This portion is the same code, just re-sized for the MapCheck 2
% -----------------------------------------------------------------------
 
elseif fileType == 2
    
        i = 1;
        M = zeros(67,55);

        for j = dose_count_start:55:dose_count_end+56

            M(i,1:55) = str2double(C{1}(j:j+54));
            i = i + 1;

        end

        row_value = M(1:end-2,1);
        col_value = M(67,1:end-2);

        M = M(1:65,3:end);      
        col_resize = transpose((-14.1:0.1:14));
        row_resize = transpose((17.1:-0.1:-17));

        M_total = zeros(length(row_resize),length(col_resize));
        M_total(1,:) = col_resize;
        M_total(:,1) = row_resize;

        [ix] = find(roundn(M_total(:,1),-2) == row_value(end));
        M_finish_x = ix;
        [iy] = find(roundn(M_total(1,:),-2) == col_value(end));
        M_finish_y = iy;

        [ix] = find(roundn(M_total(:,1),-2) == row_value(1));
        M_start_x = ix;
        [iy] = find(roundn(M_total(1,:),-2) == col_value(1));
        M_start_y = iy;

        M_total(M_start_x:5:M_finish_x,M_start_y:5:M_finish_y) = M;

end

end
