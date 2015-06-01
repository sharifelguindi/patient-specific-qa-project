function [ TPS ] = open_doseplane( filename )

%%
% Read RD dose dicom files from Eclipse (single plane)

                  info = dicominfo(filename);
                  dose = double(dicomread(filename))*info.DoseGridScaling*100;
           gridScaling = info.PixelSpacing;
dose(find(dose>10000)) = 0;                                              %#ok<FNDSB>
         StartPosition = info.ImagePositionPatient;

%%
% Checks whether image plan is Coronal or Saggittal, if niether, return
% empty array

    if info.ImageOrientationPatient == [1;0;0;0;0;-1]       % Coronal Plane %

        for i = 1:info.Columns
            col_pos(i) = StartPosition(1) + double((i-1))*gridScaling(2);   %#ok<*AGROW>
        end

        for i = 1:info.Rows
            row_pos(i) = StartPosition(3) - double((i-1))*gridScaling(1);
        end

    elseif info.ImageOrientationPatient == [0;-1;0;0;0;-1] % Saggittal Plane %

        for i = 1:info.Columns
            col_pos(i) = StartPosition(3)*(-1) + double((i-1))*gridScaling(2);
        end

        for i = 1:info.Rows
            row_pos(i) = StartPosition(2) - double((i-1))*gridScaling(1);
        end

    else
        return
    end

%% Re-interpolate dose grid on 1mm size

              new_row.start = 170;
             new_row.finish = -170;
               
              new_col.start = -170;
             new_col.finish = 170;
               
               grid_spacing = 1;
                   old_grid = dose;
               
 [ TPS ] = reshape_matrix_grid( old_grid, row_pos, col_pos, new_row, new_col, grid_spacing );

%% Resize TPS dose plane to MapCheck 2 matrix size
TPS = TPS(:,31:end-30);
    


end

