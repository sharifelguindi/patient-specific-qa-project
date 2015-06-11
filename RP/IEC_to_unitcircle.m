function [ unit_angle ] = IEC_to_unitcircle( angles )

%%
%%% This function converts the Varian IEC 61217 scale for gantry angles to 
%%% that of a unit circle from the viewpoint of facing the gantry at the
%%% foot of the treatment table.  If the angle given is not between 0 and
%%% 360 degrees, the return value is set to 1000.

[row,col] = find(angles);
vector_size = size(angles);
unit_angle = zeros(vector_size(1),vector_size(2));


  for i = 1:length(row)
    
    for j = 1:length(col)
            
            theta = angles(row(i),col(j));
        
            if theta >= 0 && theta <= 90
                unit_angle(row(i),col(j)) = abs(90 - theta);

            elseif theta > 90 && theta <= 180
                unit_angle(row(i),col(j)) = 450 - theta;

            elseif theta > 180 && theta <= 270
                unit_angle(row(i),col(j)) = 450 - theta;

            elseif theta > 270 && theta < 360
                unit_angle(row(i),col(j)) = 450 - theta;

            else
                unit_angle(row(i),col(j)) = 1000;
            end
    
    end
  end    
end

