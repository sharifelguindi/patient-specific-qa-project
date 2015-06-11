function [ ] = data_input_plan_only(root_path, destination, RP_file, dbpath)


%       Automated Gamma Analysis of Patient Specific IMRT QA at
%                 The Mayo Clinic in Arizona
%               AUTHOR : SHARIF ELGUINDI, M.S.

% This function will need the following functions in the same matlab path 
% in order to automate the gamma analysis of patient specific QA:
%               1. open_doseplan.m
%               2. mapcheck_opener.m
%               4. gamma_analysis.m
% -----------------------------------------------------------------------
% Combined with the 3 functions above, this tool will automate the gamma 
% analysis process and collect any amount of data that can similiarly be
% obtained by the MapCheck software.
% -----------------------------------------------------------------------

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%                    Declare Global Variables for data input                     %%%%%%%%%%%%%%%%                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             data_RTplan = cell(1,6);
        data_planmetrics = cell(1,16);
                 
                  warning('off','all')
                  
                  username = '';
                       pwd = '';
                       obj = 'org.sqlite.JDBC';
                       URL = ['jdbc:sqlite:',dbpath];
                 
         tablename_RTplans = 'RTplans';
          colnames_RTplans = {'plan_UID','patient_ID','study_date','treatment_site','study_description','plan_name'};
    
                        
    tablename_planmetrics = 'planmetrics';
     colnames_planmetrics = {'numbeams','PLW','PA','PM','PI','PAGW','totalMU','fluencemap_path','fluencemap_filename','FK_RTplans_planmetrics' ...
                             'modulation_type','field_size_X','field_size_Y','degree_per_MU','bankA_mm_per_MU','bankB_mm_per_MU'};                         
          
                         C = strsplit(dbpath,'\');
                         D = C(1,1:end-1);
                  pathname = strjoin(D,'\');
           fluencemap_path = [pathname,'\planmetrics\'];
        failed_destination = 'H:\imrtraw\plan_failed\';
 
    %% Pull DICOM information
    
             info = dicominfo(RP_file);
          datetime = [info.StudyDate,' ',info.StudyTime];
       study_date = [datetime(1:4),'-',datetime(5:6),'-',datetime(7:11),':',datetime(12:13),':',datetime(14:15)];
       
  
   %% Collect RP plan information, folder needs to contain IMRT QA plan RP*.dcm

   filename = strcat(RP_file);
   [ PLW, PM, PA, PAGW, PI, ~, ~, ~, ~, ~, ~, ~, ~, totalMU, beamInfo, leaf_sequence, fluencemap, jaw, modulation_type, field_size_X, field_size_Y, mech_stability ] = calc_fluence_map_V3(filename);  %#ok<ASGLU>

   info = dicominfo(filename);
   plan_name = info.RTPlanLabel;
   
          try
            study_description = info.StudyDescription;
               treatment_site = info.StudyDescription;
       catch
            study_description = plan_name;
               treatment_site = plan_name;
          end
       
          
   plan_UID = info.SOPInstanceUID;  
   plan_UID_plan = plan_UID;
   time_stamp = info.InstanceCreationTime;
   date_stamp = info.InstanceCreationDate;
   patient_ID = info.PatientID;
   patient_ID = strrep(patient_ID,'-','');
   fluencemap_filename = strcat(patient_ID,'-',date_stamp,'-',time_stamp(1:6),'-','planmetrics','.mat');
 
   numbeams = info.FractionGroupSequence.Item_1.NumberOfBeams;
   
   if PM > 1 || PM < 0
       movefile(source,failed_destination)
       PM = 2; %#ok<NASGU>
       display('Modulation Calculation Failed.')
       return
   end  
       

%% Database Insert

    %% Insert RTplans table information
    data_RTplan{1,1} = plan_UID_plan;
    data_RTplan{1,2} = patient_ID;
    data_RTplan{1,3} = study_date;
    data_RTplan{1,4} = treatment_site;
    data_RTplan{1,5} = study_description;
    data_RTplan{1,6} = plan_name;
    
    conn = database(dbpath,username,pwd,obj,URL);
    eval(['RTplanID = fetch(conn,''SELECT RTplanID FROM RTplans WHERE plan_UID=','"',plan_UID_plan,'"',''');']);
      if isempty(RTplanID) == 1
        insert(conn,tablename_RTplans,colnames_RTplans,data_RTplan);
        close(conn)
            %% Insert planmetrics information
                if PM ~= 2

                    data_planmetrics{1,1}  = numbeams;
                    data_planmetrics{1,2}  = PLW;
                    data_planmetrics{1,3}  = PA;
                    data_planmetrics{1,4}  = PM;
                    data_planmetrics{1,5}  = PI;
                    data_planmetrics{1,6}  = PAGW;
                    data_planmetrics{1,7}  = totalMU;
                    data_planmetrics{1,8}  = fluencemap_path;
                    data_planmetrics{1,9}  = fluencemap_filename;
                    data_planmetrics{1,11} = modulation_type;
                    data_planmetrics{1,12} = field_size_X;
                    data_planmetrics{1,13} = field_size_Y;
                    data_planmetrics{1,14} = mech_stability.plan_mean_deg_MU;
                    data_planmetrics{1,15} = mech_stability.plan_bankA_mm_MU;
                    data_planmetrics{1,16} = mech_stability.plan_bankB_mm_MU;

                    conn = database(dbpath,username,pwd,obj,URL);
                          eval(['RTplanID = fetch(conn,''SELECT RTplanID FROM RTplans WHERE plan_UID=','"',plan_UID_plan,'"',''');']);
                          FK_RTplans_measurements = int64(cell2mat(RTplanID));
                          FK_RTplans_planmetrics = FK_RTplans_measurements;
                          data_planmetrics{1,10} = FK_RTplans_planmetrics;
                          insert(conn,tablename_planmetrics,colnames_planmetrics,data_planmetrics);
                    close(conn)
                    
                end
    
      else 
          
        display('Plan information is already in database');
        eval(['RTplanID = fetch(conn,''SELECT RTplanID FROM RTplans WHERE plan_UID=','"',plan_UID_plan,'"',''');']);
        close(conn)      
        
      end
    
save(strcat(fluencemap_path,fluencemap_filename),'fluencemap','beamInfo','leaf_sequence','mech_stability');    

movefile(source,destination)

end




