function [ total_fluence, cp_fluence ] = deposit_leaf_dose( total_fluence, cp_fluence, MU_control_point, idx_row,  ...
                                                            idx_col_start, idx_col_end, leaf_size, leaf_gap, use_plw )

   if leaf_size == 10
       
       if use_plw == 1
            MU_control_point = 2*MU_control_point;
       end
       
      total_fluence(idx_row-1:idx_row+2,idx_col_start:idx_col_end) = total_fluence(idx_row-1:idx_row+2,idx_col_start:idx_col_end) + MU_control_point;
      cp_fluence(idx_row-1:idx_row+2,idx_col_start:idx_col_end)    = MU_control_point;
            
   else
       
      total_fluence(idx_row:idx_row+1,idx_col_start:idx_col_end)   = total_fluence(idx_row:idx_row+1,idx_col_start:idx_col_end) + MU_control_point;
      cp_fluence(idx_row:idx_row+1,idx_col_start:idx_col_end)      = MU_control_point;
            
   end

end

