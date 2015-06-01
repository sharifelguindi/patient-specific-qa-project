function [ jaw ] = jaw_size( beamInfo )

load('leaf_info.mat');
beamNames = fieldnames(beamInfo);

 for beam_num = 1:length(beamNames)
    
    jaw.(char(beamNames(beam_num))).X1 = beamInfo.(char(beamNames(beam_num))).BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(1);
    jaw.(char(beamNames(beam_num))).X2 = beamInfo.(char(beamNames(beam_num))).BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(2);
    jaw.(char(beamNames(beam_num))).Y1 = beamInfo.(char(beamNames(beam_num))).BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(1);
    jaw.(char(beamNames(beam_num))).Y2 = beamInfo.(char(beamNames(beam_num))).BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(2);  
    
    ind_Y1 = find(leaf_info(:,2)>jaw.(char(beamNames(beam_num))).Y1);
    ind_Y2 = find(leaf_info(:,2)<jaw.(char(beamNames(beam_num))).Y2);
    
    jaw.(char(beamNames(beam_num))).leaf_ind = intersect(ind_Y1,ind_Y2);
    
 end
 
end

