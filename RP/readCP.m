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
     
     FN = char(fieldNames(i));
          
     %%% Check if field is "Dynamic", if so, proceed with data extraction
     if strcmp(info.BeamSequence.(FN).BeamType,'DYNAMIC') == 1
        
        %%% nControl is the number of control points for current beam
        nControl = info.BeamSequence.(FN).NumberOfControlPoints;
        
        %%% controlNames stores the names of each control point structure
        %%% that contains all the leaf sequence information
        controlNames = fieldnames(info.BeamSequence.(FN).ControlPointSequence);
        cN_init = char(controlNames(1));  
        
        %%% beamInfo."BeamName" stores all the relevant beam information
        %%% from the dicom RP file
        beamInfo.(FN) = info.BeamSequence.(FN).ControlPointSequence.(cN_init);
        
        %% Extract the MU for the individual beam
        MU_names = fieldnames(info.FractionGroupSequence.Item_1.ReferencedBeamSequence);
        for k = 1:length(MU_names)
            
            ref_num = info.FractionGroupSequence.Item_1.ReferencedBeamSequence.(char(MU_names(k))).ReferencedBeamNumber;
            if info.BeamSequence.(FN).BeamNumber == ref_num
                beam_MU = info.FractionGroupSequence.Item_1.ReferencedBeamSequence.(char(MU_names(k))).BeamMeterset;
            end
            
        end
        
        %% For the first control point, the leaf sequence information is stored in "Item_3"
        leaf_sequence.(FN)(1,1) = info.BeamSequence.(FN).ControlPointSequence.(cN_init).CumulativeMetersetWeight*(beam_MU);
        leaf_sequence.(FN)(2,1) = info.BeamSequence.(FN).ControlPointSequence.(cN_init).GantryAngle;
        leaf_sequence.(FN)(3:122,1) = info.BeamSequence.(FN).ControlPointSequence.(cN_init).BeamLimitingDevicePositionSequence.Item_3.LeafJawPositions;
        
        
        
        %% For the second and rest of the control points, the leaf sequence information is stored in "Item_1"
        for j = 2:nControl
          
          cp_N = char(controlNames(j));
          
          if strcmp(info.BeamSequence.(FN).ControlPointSequence.(cN_init).GantryRotationDirection,'NONE')==1
              leaf_sequence.(FN)(1,j) = info.BeamSequence.(FN).ControlPointSequence.(cp_N).CumulativeMetersetWeight*(beam_MU);
              leaf_sequence.(FN)(2,j) = info.BeamSequence.(FN).ControlPointSequence.(cN_init).GantryAngle;  
              leaf_sequence.(FN)(3:122,j) = info.BeamSequence.(FN).ControlPointSequence.(cp_N).BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions;
          else  
              leaf_sequence.(FN)(1,j) = info.BeamSequence.(FN).ControlPointSequence.(cp_N).CumulativeMetersetWeight*(beam_MU);
              leaf_sequence.(FN)(2,j) = info.BeamSequence.(FN).ControlPointSequence.(cp_N).GantryAngle;  
              leaf_sequence.(FN)(3:122,j) = info.BeamSequence.(FN).ControlPointSequence.(cp_N).BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions;
          end
          
        end
        
     end
     
    end

end

