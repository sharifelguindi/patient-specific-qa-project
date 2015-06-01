function [ beamInfo, leaf_sequence ] = readCP( filename )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%  This program reads the leaf control points for a given RP                     %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%  plan and stores it in 2 structure variables for ease of calculation           %%%%%%%%%%%%%%%%                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Read in Dicom file with given filename and store field structure names in variable "fieldNames"
info = dicominfo(filename);
fieldNames = fieldnames(info.BeamSequence);

%% Begin Extraction of Leaf Sequence data
    for i = 1:length(fieldNames)    
     
     %%% Check if field is "Dynamic", if so, proceed with data extraction
     if strcmp(info.BeamSequence.(char(fieldNames(i))).BeamType,'DYNAMIC') == 1
        
        %%% nControl is the number of control points for current beam
        nControl = info.BeamSequence.(char(fieldNames(i))).NumberOfControlPoints;
        
        %%% controlNames stores the names of each control point structure
        %%% that contains all the leaf sequence information
        controlNames = fieldnames(info.BeamSequence.(char(fieldNames(i))).ControlPointSequence);
        
        %%% beamInfo."BeamName" stores all the relevant beam information
        %%% from the dicom RP file
        beamInfo.(char(fieldNames(i))) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(1)));
        
        %% Extract the MU for the individual beam
        MU_names = fieldnames(info.FractionGroupSequence.Item_1.ReferencedBeamSequence);
        for k = 1:length(MU_names)
            ref_num = info.FractionGroupSequence.Item_1.ReferencedBeamSequence.(char(MU_names(k))).ReferencedBeamNumber;
            if info.BeamSequence.(char(fieldNames(i))).BeamNumber == ref_num
                beam_MU = info.FractionGroupSequence.Item_1.ReferencedBeamSequence.(char(MU_names(k))).BeamMeterset;
            end
        end
        
        %% For the first control point, the leaf sequence information is stored in "Item_3"
        leaf_sequence.(char(fieldNames(i)))(1,1) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(1))).CumulativeMetersetWeight*(beam_MU);
        leaf_sequence.(char(fieldNames(i)))(2,1) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(1))).GantryAngle;
        leaf_sequence.(char(fieldNames(i)))(3:122,1) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(1))).BeamLimitingDevicePositionSequence.Item_3.LeafJawPositions;
        
        
        
        %% For the second and rest of the control points, the leaf sequence information is stored in "Item_1"
        for j = 2:nControl
           
          if strcmp(info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(1))).GantryRotationDirection,'NONE')==1
              leaf_sequence.(char(fieldNames(i)))(1,j) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(j))).CumulativeMetersetWeight*(beam_MU);
              leaf_sequence.(char(fieldNames(i)))(2,j) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(1))).GantryAngle;  
              leaf_sequence.(char(fieldNames(i)))(3:122,j) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(j))).BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions;
          else  
              leaf_sequence.(char(fieldNames(i)))(1,j) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(j))).CumulativeMetersetWeight*(beam_MU);
              leaf_sequence.(char(fieldNames(i)))(2,j) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(j))).GantryAngle;  
              leaf_sequence.(char(fieldNames(i)))(3:122,j) = info.BeamSequence.(char(fieldNames(i))).ControlPointSequence.(char(controlNames(j))).BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions;
          end
        end
        
     end
     
    end

end

