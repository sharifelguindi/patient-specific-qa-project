function [ PLW, PM, PA, PAGW, PI, BA, BAGW, BI, BM, AA, AP, AI, MP, totalMU, beamInfo, leaf_sequence, fluencemap, jaw, modulation_type, field_size_X, field_size_Y, mech_stability ] = calc_fluence_map_V3(filename)

%% Read in Necessary Data about Treatment Plan
%   [fileName,filePath] = uigetfile(['RP*.dcm'], 'Please select MapCHECK file');
%%% Loads the information of the location and relative size of each of the
%%% 60 leaves in a Varian MLC.  This will need to be updated according to
%%% machine parameters.
load('leaf_info.mat');
PLW = 0;
mean_deg_MU = 0;
bankA_mean_mm_MU = 0;
bankB_mean_mm_MU = 0;
pixel_size = 2.5;
totalMU = 0;
 field_size_X = 0;
 field_size_Y = 0;
%%% readCP gives the beamInfo and leaf_sequence information for all dynamic beams
    [ beamInfo, leaf_sequence ] = readCP( filename );
    
%%% Store the structure name of the all the beams in cell "beamNames"
                      beamNames = fieldnames(leaf_sequence);

%%% Store the jaw size information for each beam in the structure "jaw" the
%%% structure is jaw."beamName"."jaw name (X1,Y1 etc)"
                        [ jaw ] = jaw_size( beamInfo );
                        
%%% Create an empty structure array "fluence_matrix" for each control point
%%% and beam, with an appropriate size matrix for the given jaw
             [ fluence_matrix ] = create_fluence_matrix( jaw, beamNames );
             
BA   = zeros(2,length(beamNames));
BAGW = zeros(2,length(beamNames));
BI   = zeros(2,length(beamNames));
BM   = zeros(2,length(beamNames));

%% Begin "delivering" the radiation through each fluence_matrix, select first beam 
    for beam_num = 1:length(beamNames)
        
        C = unique(leaf_sequence.(char(beamNames(beam_num)))(2,:));
        if length(C) > 1
            modulation_type = 'VMAT';
        else
            modulation_type = 'IMRT';
        end
        
        leafpct = 0;
        %%% dataSize stores the row,col of the leaf_sequences for a given
        %%% dynamic beam.  For RA treatments, this is typically 122,178 - i.e,
        %%% 2 rows for gantry and MU at each control point, 120 leaves and 178
        %%% control points.
        dataSize = size(leaf_sequence.(char(beamNames(beam_num))));

        %%% The function jaw_size, uses the jaws to determine if a leaf is
        %%% sitting behind the jaw or not, it stores the indices in relation to
        %%% the leaf_sequence of which leaves are potentially being modulated
        %%% across the beam defined by jaws
        leaves_used = jaw.(char(beamNames(beam_num))).leaf_ind;

        %%% Grab the collimator rotation of the beam being analyzed
        col_angle = beamInfo.(char(beamNames(beam_num))).BeamLimitingDeviceAngle;
        
        if col_angle > 180
            
               col_angle = col_angle - 360;
               
        end
        
        col_angle = col_angle*(-1);
        
        %%% This just gives more readable code and stores the jaw positions in
        %%% shorter length variables
        
        X1 =  jaw.(char(beamNames(beam_num))).X1;
        X2 =  jaw.(char(beamNames(beam_num))).X2;
        Y1 =  jaw.(char(beamNames(beam_num))).Y1;
        Y2 =  jaw.(char(beamNames(beam_num))).Y2;
        field_size_X = field_size_X + (X2-X1);
        field_size_Y = field_size_Y + (Y2-Y1);
    %% Define variables specific for the control point
        %%% Create structure MP (machine parameters) which has a MU structure 
        %%% defining the MU delivered at each CP and define the total MU.
        %%% It Also has a Gantry structure, defining the angle of each CP 
        MP.(char(beamNames(beam_num))).MU = zeros(1,dataSize(2));

    %% Store the row and column positions of the "fluence matrix" about to be loaded
    
        row_position  = fluence_matrix.(char(beamNames(beam_num))).row_position;
        col_position  = fluence_matrix.(char(beamNames(beam_num))).col_position;
        total_fluence = fluence_matrix.(char(beamNames(beam_num))).matrix;
        
    %% Calculate avg and standard deviation of degrees/MU
    
        MU_diff_per_CP     = diff(leaf_sequence.(char(beamNames(beam_num)))(1,:));
        degree_diff_per_CP = diff(leaf_sequence.(char(beamNames(beam_num)))(2,:));
        degree_MU          = MU_diff_per_CP./degree_diff_per_CP;
        
        mech_stability.(char(beamNames(beam_num))).mean_deg_MU = mean(degree_MU);
        mech_stability.(char(beamNames(beam_num))).std_deg_MU  = std(degree_MU);
        
        bankA_tot = leaf_sequence.(char(beamNames(beam_num)))(63:end,:); 
        bankAdiff = diff(bankA_tot(leaves_used,:),1,2);
        bankB_tot = leaf_sequence.(char(beamNames(beam_num)))(3:62,:);
        bankBdiff = diff(bankB_tot(leaves_used,:),1,2);
        
        bankA_mm_deg = zeros(size(bankAdiff));
        bankB_mm_deg = zeros(size(bankBdiff));
        
        counter = 1;
        for i = 1:length(MU_diff_per_CP)
            
            if MU_diff_per_CP(i) ~= 0
                bankA_mm_deg(:,counter) = bankAdiff(:,i)/MU_diff_per_CP(i);
                bankB_mm_deg(:,counter) = bankBdiff(:,i)/MU_diff_per_CP(i);
                counter = counter + 1;
            end
                
        end
        
        mech_stability.(char(beamNames(beam_num))).bankA_mean_mm_MU = rms((bankA_mm_deg(:)));
        mech_stability.(char(beamNames(beam_num))).bankA_std_mm_MU  = std((bankA_mm_deg(:)));

        mech_stability.(char(beamNames(beam_num))).bankB_mean_mm_MU = rms((bankB_mm_deg(:)));
        mech_stability.(char(beamNames(beam_num))).bankB_std_mm_MU  = std((bankB_mm_deg(:)));
        
    %% Begin for loop over each control point of the current beam analyzed
    
        for control_point = 1:dataSize(2)

        
        %% Distrube MU over all Control Points
        %%% This small if statement distributes the MU about each control point.
        %%% For the first control point, the MU delivered is the difference of
        %%% MU between the first and second control points divided by 2.  This
        %%% is repeated until the last control point 
         if control_point == dataSize(2)
             
             MP.(char(beamNames(beam_num))).totalMU           = leaf_sequence.(char(beamNames(beam_num)))(1,control_point);
             MP.(char(beamNames(beam_num))).MU(control_point) = MP.(char(beamNames(beam_num))).MU(control_point);
             
         else
             
             shared_MU = (leaf_sequence.(char(beamNames(beam_num)))(1,control_point + 1) - leaf_sequence.(char(beamNames(beam_num)))(1,control_point))/2;
             MP.(char(beamNames(beam_num))).MU(control_point)   = MP.(char(beamNames(beam_num))).MU(control_point) + shared_MU;
             MP.(char(beamNames(beam_num))).MU(control_point+1) = MP.(char(beamNames(beam_num))).MU(control_point+1) + shared_MU;  
             
         end
         
        MP.(char(beamNames(beam_num))).gantry(1,control_point) = leaf_sequence.(char(beamNames(beam_num)))(2,control_point);
        MP.(char(beamNames(beam_num))).gantry(2,control_point) = IEC_to_unitcircle(MP.(char(beamNames(beam_num))).gantry(control_point));
        MP.(char(beamNames(beam_num))).gantry(3,control_point) = abs(cos(degtorad(MP.(char(beamNames(beam_num))).gantry(control_point))));

    %%% The MU delivered at the control is stored in MU_control_point
        MU_control_point = MP.(char(beamNames(beam_num))).MU(control_point);
        
    %%% The fluence matrix for the given control point is stored as cp_fluence
        cp_fluence = fluence_matrix.(char(beamNames(beam_num))).matrix;
    cp_fluence_plw = fluence_matrix.(char(beamNames(beam_num))).matrix;
    
    %%% Seperate the leaf_sequence data in to bank A and bank B.  Bank A is
    %%% behind the X2 jaw, and bank B is behind the X1 jaw
        bankA = leaf_sequence.(char(beamNames(beam_num)))(63:end,control_point); %% X2 Jaw
        bankB = leaf_sequence.(char(beamNames(beam_num)))(3:62,control_point);   %% X1 Jaw

    %% Begin for loop over the leaves being used (stored as indices "leaves_used")
                 for leaf_num = 1:length(leaves_used)

                     leaf_size = leaf_info(leaves_used(leaf_num),3);
                                         
                     %% Conditional Statement for creating fluence map                    
                     %%% Both leaves under the X2 Jaw (not in beam)
                     if bankA(leaves_used(leaf_num)) > X2 && bankB(leaves_used(leaf_num)) > X2   

                            %%% No update to cp_fluence needed

                     %%% Both leaves under the X1 Jaw (not in beam)
                     elseif bankA(leaves_used(leaf_num)) < X1 && bankB(leaves_used(leaf_num)) < X1 

                            %%% No update to cp_fluence needed

                     %%% Bank A leaf is under the X2 jaw, but bank B is not
                     elseif bankA(leaves_used(leaf_num)) > X2 && bankB(leaves_used(leaf_num)) > X1 && bankB(leaves_used(leaf_num)) < X2 

                        [~, idx_col_end]   = min(abs(col_position - X2));
                        [~, idx_col_start] = min(abs(col_position - bankB(leaves_used(leaf_num))));
                        [~, idx_row]       = min(abs(row_position - leaf_info(leaves_used(leaf_num),2)));
                        leaf_gap           =  X2 - bankB(leaves_used(leaf_num));
                               
                        [ total_fluence, cp_fluence ] = deposit_leaf_dose( total_fluence, cp_fluence,  ...
                                                                           MU_control_point, idx_row,  ...
                                                                           idx_col_start, idx_col_end, ...
                                                                           leaf_size, leaf_gap, 0 ); 
                                                                       
                        [ ~, cp_fluence_plw ] = deposit_leaf_dose( total_fluence, cp_fluence_plw,      ...
                                                                           MU_control_point, idx_row,  ...
                                                                           idx_col_start, idx_col_end, ...
                                                                           leaf_size, leaf_gap, 1 ); 
                     %%% Bank B leaf is under the X1 jaw, but bank A is not
                     elseif bankB(leaves_used(leaf_num)) < X1 && bankA(leaves_used(leaf_num)) > X1 && bankA(leaves_used(leaf_num)) < X2 

                        [~, idx_col_start] = min(abs(col_position - X1));
                        [~, idx_col_end]   = min(abs(col_position - bankA(leaves_used(leaf_num))));
                        [~, idx_row]       = min(abs(row_position - leaf_info(leaves_used(leaf_num),2)));
                        leaf_gap           =  bankA(leaves_used(leaf_num)) - X1;
                               
                        [ total_fluence, cp_fluence ] = deposit_leaf_dose( total_fluence, cp_fluence,  ...
                                                                           MU_control_point, idx_row,  ...
                                                                           idx_col_start, idx_col_end, ...
                                                                           leaf_size, leaf_gap, 0 ); 
                                                                       
                        [ ~, cp_fluence_plw ] = deposit_leaf_dose( total_fluence, cp_fluence_plw,      ...
                                                                           MU_control_point, idx_row,  ...
                                                                           idx_col_start, idx_col_end, ...
                                                                           leaf_size, leaf_gap, 1 ); 

                     %%% Both Bank A and B are within the jaws, can use there
                     %%% positions to define size of field
                     else

                        [~, idx_col_start] = min(abs(col_position-bankB(leaves_used(leaf_num))));
                        [~, idx_col_end]   = min(abs(col_position-bankA(leaves_used(leaf_num))));
                        [~, idx_row]       = min(abs(row_position-leaf_info(leaves_used(leaf_num),2)));
                        leaf_gap           =  bankA(leaves_used(leaf_num)) - bankB(leaves_used(leaf_num));

                        [ total_fluence, cp_fluence ] = deposit_leaf_dose( total_fluence, cp_fluence,  ...
                                                                           MU_control_point, idx_row,  ...
                                                                           idx_col_start, idx_col_end, ...
                                                                           leaf_size, leaf_gap, 0 ); 
                                                                       
                        [ ~, cp_fluence_plw ] = deposit_leaf_dose( total_fluence, cp_fluence_plw,      ...
                                                                           MU_control_point, idx_row,  ...
                                                                           idx_col_start, idx_col_end, ...
                                                                           leaf_size, leaf_gap, 1 ); 
                                                                       
                     end

                 end

           %% Define structure array name for each control point
           string = ['cp_',num2str(control_point)];
           
           %% Compute the percentage of MU that was deliverd by the larger leafs
           ind = find(cp_fluence_plw >= 2*MU_control_point);
           ind_2 = find(cp_fluence_plw > 0);
           value = (length(ind)/length(ind_2));
           
           if isnan(value) == 1 || isinf(value)
               value = 0;
           end
           
           fluencemap.leafpct.(char(beamNames(beam_num))).(char(string)) = value;
           leafpct = leafpct + value;
           
           %% Compute the area and perimeter of each control point
           [ area, perimeter ] = fluence_AA_AP( cp_fluence, pixel_size );
           AP.(char(beamNames(beam_num)))(1,control_point) = perimeter;
           AA.(char(beamNames(beam_num)))(1,control_point) = area;
           GW.(char(beamNames(beam_num)))(1,control_point) = area*MP.(char(beamNames(beam_num))).gantry(3,control_point);
           AI.(char(beamNames(beam_num)))(1,control_point) = (sum(perimeter))^2/(4*pi*sum(area));
           
           cp_fluence = imrotate(cp_fluence,col_angle,'crop');
           fluencemap.cp.(char(beamNames(beam_num))).(char(string)) = cp_fluence;

        end
    
       
    [ area_total, ~ ] = fluence_AA_AP( total_fluence, pixel_size );
    fluencemap.total.(char(beamNames(beam_num))).area = area_total;
    fluencemap.total.(char(beamNames(beam_num))).flu  = imrotate(total_fluence,col_angle,'crop');
    AI.(char(beamNames(beam_num)))(isnan(AI.(char(beamNames(beam_num))))) = 0;
    U_AA = fluencemap.total.(char(beamNames(beam_num))).area;
    
    MU_AA_weighted = MP.(char(beamNames(beam_num))).MU.*AA.(char(beamNames(beam_num)));
    BA(1,beam_num) = (sum(MU_AA_weighted(1:end)))./(MP.(char(beamNames(beam_num))).totalMU);
    BA(2,beam_num) = MP.(char(beamNames(beam_num))).totalMU;
    
    MU_AA_gantry_weighted = MP.(char(beamNames(beam_num))).MU.*GW.(char(beamNames(beam_num)));
    BAGW(1,beam_num) = (sum(MU_AA_gantry_weighted(1:end)))./(MP.(char(beamNames(beam_num))).totalMU);
    BAGW(2,beam_num) = MP.(char(beamNames(beam_num))).totalMU;
    
    MU_AI_weighted = MP.(char(beamNames(beam_num))).MU.*AI.(char(beamNames(beam_num)));
    BI(1,beam_num) = (sum(MU_AI_weighted(1:end)))./(MP.(char(beamNames(beam_num))).totalMU);
    BI(2,beam_num) = MP.(char(beamNames(beam_num))).totalMU;
    
    BM(1,beam_num) = 1 - ((BA(1,beam_num))./((U_AA))); 
    BM(2,beam_num) = MP.(char(beamNames(beam_num))).totalMU;
    PLW = PLW + leafpct/dataSize(2);
    
    mean_deg_MU = mean_deg_MU + abs(mech_stability.(char(beamNames(beam_num))).mean_deg_MU);
    bankA_mean_mm_MU = bankA_mean_mm_MU + mech_stability.(char(beamNames(beam_num))).bankA_mean_mm_MU; 
    bankB_mean_mm_MU = bankB_mean_mm_MU + mech_stability.(char(beamNames(beam_num))).bankB_mean_mm_MU;
    totalMU      = totalMU + MP.(char(beamNames(beam_num))).totalMU;
    
    end
    
   PM           = sum((BM(1,:).*BM(2,:))/sum(BM(2,:)));
   PI           = sum((BI(1,:).*BI(2,:))/sum(BI(2,:)));
   PA           = sum((BA(1,:).*BA(2,:))/sum(BA(2,:)));
   PA           = PA/(10^2); % Convert to cm^2
   PAGW         = sum((BAGW(1,:).*BAGW(2,:))/sum(BAGW(2,:)));
   PAGW         = PAGW/(10^2);   
   
   PLW          = PLW/(length(beamNames));
   field_size_X = (field_size_X/(length(beamNames)))*(1/10);
   field_size_Y = (field_size_Y/(length(beamNames)))*(1/10);
   
   if isinf(mean_deg_MU) == 1
       mean_deg_MU = 0;
   end
   
   mech_stability.plan_mean_deg_MU = mean_deg_MU/(length(beamNames));
   mech_stability.plan_bankA_mm_MU = bankA_mean_mm_MU/(length(beamNames));
   mech_stability.plan_bankB_mm_MU = bankB_mean_mm_MU/(length(beamNames));
   
   
   
   
    
end
