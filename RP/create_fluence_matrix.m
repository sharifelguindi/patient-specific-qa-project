function [ fluence_matrix ] = create_fluence_matrix( jaw, beamNames )

buffer    = 50;
step_size = 2.5; 

for beam_num = 1:length(beamNames)
    
  col_position = (jaw.(char(beamNames(beam_num))).X1 - buffer:step_size:jaw.(char(beamNames(beam_num))).X2 + buffer);
  row_position = (roundn(jaw.(char(beamNames(beam_num))).Y1,1) - buffer:step_size:roundn(jaw.(char(beamNames(beam_num))).Y2,1) + buffer);
  fluence_matrix.(char(beamNames(beam_num))).matrix = zeros(length(row_position),length(col_position));
  fluence_matrix.(char(beamNames(beam_num))).row_position = row_position;
  fluence_matrix.(char(beamNames(beam_num))).col_position = col_position;
       
end

