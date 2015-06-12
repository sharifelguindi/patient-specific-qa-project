function [ new_grid ] = reshape_matrix_grid( old_grid, row_pos, col_pos, new_row, new_col, grid_spacing )


               [Y,X] = ndgrid(row_pos,col_pos);
                   V = old_grid;
                   
      if new_row.start - new_row.finish > 0
          grid_spacing_row = (-1)*grid_spacing;
      else
          grid_spacing_row = grid_spacing; 
      end
      
      if new_col.start - new_col.finish > 0
          grid_spacing_col = (-1)*grid_spacing;
      else
          grid_spacing_col = grid_spacing;
      end
      
                   
      row_pos_format = (new_row.start:grid_spacing_row:new_row.finish);
      col_pos_format = (new_col.start:grid_spacing_col:new_col.finish);
 [Y_format,X_format] = ndgrid(row_pos_format,col_pos_format);
                  Vq = interp2(X,Y,V,X_format,Y_format);
       Vq(isnan(Vq)) = 0 ;
            new_grid = Vq;
       

end

