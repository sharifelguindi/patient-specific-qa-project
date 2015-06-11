function [ ] = data_input_gui_batch(root_path, destination, dbpath)

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
                   steps = 1;
             data_RTplan = cell(1,6);
        data_measurement = cell(1,8);
          data_qaresults = cell(1,11);
             format_time = 'yyyy-mm-dd HH:MM:SS';
          
                 d = dir(root_path);
              isub = [d(:).isdir]; %# returns logical vector
           folders = {d(isub).name}';
          folders(ismember(folders,{'.','..','ArcCHECK'})) = [];

                 
                  warning('off','all')
                  
                  username = '';
                       pwd = '';
                       obj = 'org.sqlite.JDBC';
                       URL = ['jdbc:sqlite:',dbpath];
                 
         tablename_RTplans = 'RTplans';
          colnames_RTplans = {'plan_UID','patient_ID','study_date','treatment_site','study_description','plan_name'};
    
    tablename_measurements = 'measurements';
     colnames_measurements = {'instance_UID','plan_dose_path','plan_dose_filename','meas_dose_path','meas_dose_filename','machine_name', ...
                              'dose_scaling','FK_RTplans_measurements','background_mean','background_stdev'};
          
      tablename_qaresults = 'qa_results';
       colnames_qaresults = {'dta','dose_criteria','threshold','van_dyk','numpts_analyzed', ...
                              'gpr','avg_dose_ratio','stdev_dose_ratio','gamma_map_path','gamma_map_filename','FK_measurements_qa_results'};
                          
    tablename_dosemetrics = 'dosemetrics';
     colnames_dosemetrics = {'mean_target_dose','mean_target_gradient','mean_pneumbra_gradient','mean_lowdose_gradient','mean_lowdose_dose',...
                             'target_dose_diff','target_dose_stdev','target_dose_numpoints','pneumbra_dose_diff','pneumbra_dose_stdev', ...
                             'pneumbra_dose_numpoints','low_dose_diff','low_dose_stdev','low_dose_numpoints','FK_measurements_dosemetrics'};
                         
    tablename_planmetrics = 'planmetrics';
     colnames_planmetrics = {'numbeams','PLW','PA','PM','PI','PAGW','totalMU','fluencemap_path','fluencemap_filename','FK_RTplans_planmetrics' ...
                             'modulation_type','field_size_X','field_size_Y','degree_per_MU','bankA_mm_per_MU','bankB_mm_per_MU'};                         
          
            C = strsplit(dbpath,'\');
            D = C(1,1:end-1);
            pathname = strjoin(D,'\');
            plan_dose_path = [pathname,'\plan_dose\'];
            meas_dose_path = [pathname,'\meas_dose\'];
            gamma_map_path = [pathname,'\gamma_map\'];
           fluencemap_path = [pathname,'\planmetrics\'];
        failed_destination = 'H:\imrtraw\plan_failed\';
         
%%
h = waitbar(0,'Please wait...');
pt_num_start = 1;
pt_num_end = length(folders);
total_steps = (pt_num_end - pt_num_start + 1)*120;

for i = pt_num_start:pt_num_end
    
    tic;
% -----------------------------------------------------------------------
% z is a place holder that steps through the cell array ' ptdata '. 
% -----------------------------------------------------------------------

    z = 1;

% -----------------------------------------------------------------------
% Input the path to the file where patient data is stored.  The folder
% should  contain 1 RD*.dcm eclipse dose file and 1 .txt mapcheck file and
% the excel sheet containing the dose scaling value.  The 2 files 
% should be registered such that there centers are the same.  
% -----------------------------------------------------------------------

     source = strcat(root_path,'\',cell2mat(folders(i)));
   TPS_file = dir(strcat(root_path,'\',cell2mat(folders(i)),'\','RD*.dcm'));
   
    MC_file = dir(strcat(root_path,'\', cell2mat(folders(i)),'\','*.txt'));
    
     if length(MC_file) > 1;
         MC_file = dir(strcat(root_path,'\', cell2mat(folders(i)),'\','mc*.txt'));
     end
   
   cal_file = dir(strcat(root_path,'\', cell2mat(folders(i)),'\','*.xls'));
        
% -----------------------------------------------------------------------
% Use 2 of the 3 functions listed above to extract the MapCheck dose matrix
% and the TPS dose matrix and put them in a functional form.
% -----------------------------------------------------------------------

   [ MC ] = mapcheck_opener_V2( strcat(root_path, '\', cell2mat(folders(i)),'\', MC_file.name ));
        MC = MC(2:end,2:end);
        
   [ TPS ] = open_doseplane( strcat(root_path, '\', cell2mat(folders(i)),'\', TPS_file.name ));
    
    %% Pull Excel File Information
        [~,~,raw] = xlsread(strcat(root_path, '\', cell2mat(folders(i)),'\', cal_file.name ), 'MapPhan dose scaled', 'B3:D33');
        dose_scaling = double(cell2mat(raw(13,2)));
        TPS = TPS*dose_scaling;
        
        plan_name = cell2mat(raw(3,1));
        if isempty(plan_name) == 1 || isnumeric(plan_name) == 1
            plan_name = 'unknown';
        end
        
        name = plan_name;
        name = strrep(name,'/','-');
        name = strrep(name,'\','-');
        name = strrep(name,'#','-');
        name = strrep(name,'.','-');
        name = strrep(name,':','-');
        
        ind_C = find(strcmp(raw,'CTX')==1);
        ind_D = find(strcmp(raw,'DTX')==1);
        ind_A = find(strcmp(raw,'AEX')==1);

        if isempty(ind_A) == 0
            machine_name = raw(ind_A);
%             MC = MC*(0.9856);
%             machine_name = 'AEX_scaled';
        elseif isempty(ind_C) == 0
            machine_name = raw(ind_C);
%             MC = MC*(1.0009);
%             machine_name = 'CTX_scaled';
        elseif isempty(ind_D) == 0
            machine_name = raw(ind_D);
%             MC = MC*(1.0196);
%             machine_name = 'DTX_scaled';
        else
            machine_name = 'unknown';
        end         
        machine_name = char(machine_name);
        
    %% Pull DICOM information
    
             info = dicominfo(strcat(root_path, '\', cell2mat(folders(i)),'\', TPS_file.name ));
    plan_UID_plan = info.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
    
        t = now;
        instance_UID = datestr(t,format_time);
        date_time_stamp = strrep(instance_UID,' ','');
        date_time_stamp = strrep(date_time_stamp,':','');


       patient_ID = info.PatientID;
       patient_ID = strrep(patient_ID,'-','');
         datetime = [info.StudyDate,' ',info.StudyTime];
       study_date = [datetime(1:4),'-',datetime(5:6),'-',datetime(7:11),':',datetime(12:13),':',datetime(14:15)];
       
       try
            study_description = info.StudyDescription;
               treatment_site = info.StudyDescription;
       catch
            study_description = char(plan_name);
               treatment_site = char(plan_name);
       end
   
       time_stamp = info.InstanceCreationTime;
       date_stamp = info.InstanceCreationDate;

   %% Save plan and meas pathnames
        meas_dose_filename = strcat(patient_ID,'-',date_stamp,'-',time_stamp(1:6),'-',name,'-','meas','-',date_time_stamp,'.mat');
        plan_dose_filename = strcat(patient_ID,'-',date_stamp,'-',time_stamp(1:6),'-',name,'-','plan','-',date_time_stamp,'.mat');
  
   %% Pull Background information (only if not composite text file)
          okay = 0;
          try
            [mapCheckArray,~] = readMapCheck(strcat(root_path, '\', cell2mat(folders(i)),'\', MC_file.name ));
            okay = 1;
          catch
            disp('Composite Dose File')  
          end

          if okay == 1

              background = mapCheckArray(:,3:end,1);
              ind = find(background>0);
              background_mean = mean(background(ind));
              background_stdev = std(background(ind));

          else

              background_mean = 0;
              background_stdev = 0;

          end
      
   %% Collect plane of measurement data such as target dose, gradients and differences between planned and measured 
 [ mean_target_gradient, mean_target_dose, mean_pneumbra_gradient, ...
   mean_lowdose_gradient, mean_lowdose_dose, target, pneumbra, low_dose ] = dose_plane_metrics( TPS, MC );


                   data_dosemetrics{1,1}  = mean_target_dose;
                   data_dosemetrics{1,2}  = mean_target_gradient;              
                   data_dosemetrics{1,3}  = mean_pneumbra_gradient;
                   data_dosemetrics{1,4}  = mean_lowdose_gradient;
                   data_dosemetrics{1,5}  = mean_lowdose_dose;
                   data_dosemetrics{1,6}  = target.dose_diff;
                   data_dosemetrics{1,7}  = target.stdev;
                   data_dosemetrics{1,8}  = target.numpoints;
                   data_dosemetrics{1,9}  = pneumbra.dose_diff;
                   data_dosemetrics{1,10} = pneumbra.stdev;
                   data_dosemetrics{1,11} = pneumbra.numpoints;
                   data_dosemetrics{1,12} = low_dose.dose_diff;
                   data_dosemetrics{1,13} = low_dose.stdev;
                   data_dosemetrics{1,14} = low_dose.numpoints;
 
   
   %% Collect RP plan information, folder needs to contain IMRT QA plan RP*.dcm
   RP_file = dir(strcat(root_path,'\', cell2mat(folders(i)),'\','RP*.dcm'));
   filename = strcat(root_path, '\', cell2mat(folders(i)),'\', RP_file.name );
   [ PLW, PM, PA, PAGW, PI, ~, ~, ~, ~, ~, ~, ~, ~, totalMU, beamInfo, leaf_sequence, fluencemap, jaw, modulation_type, field_size_X, field_size_Y, mech_stability ] = calc_fluence_map_V3(filename);  %#ok<ASGLU>

   info = dicominfo(filename);
   plan_UID = info.SOPInstanceUID;  %#ok<NASGU>
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
    data_RTplan{1,6} = char(plan_name);
    
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
        FK_RTplans_measurements = int64(cell2mat(RTplanID));
        close(conn)      
        
      end
    
    %% Insert measurements table information
    data_measurement{1,1} = instance_UID;
    data_measurement{1,2} = plan_dose_path;
    data_measurement{1,3} = plan_dose_filename;
    data_measurement{1,4} = meas_dose_path;
    data_measurement{1,5} = meas_dose_filename;
    data_measurement{1,6} = machine_name;
    data_measurement{1,7} = dose_scaling;
    data_measurement{1,9} = background_mean;
    data_measurement{1,10} = background_stdev;
    
    conn = database(dbpath,username,pwd,obj,URL);
    
        data_measurement{1,8} = FK_RTplans_measurements;
        insert(conn,tablename_measurements,colnames_measurements,data_measurement);
   
    close(conn)
   
    %% Insert dosemetrics table data
    conn = database(dbpath,username,pwd,obj,URL);
    
         eval(['measurementID = fetch(conn,''SELECT measurementID FROM measurements WHERE instance_UID=','"',instance_UID,'"',''');']);
         FK_measurements_dosemetrics = int64(cell2mat(measurementID));
              data_dosemetrics{1,15} = FK_measurements_dosemetrics;
         insert(conn,tablename_dosemetrics,colnames_dosemetrics,data_dosemetrics);
         
    close(conn)
   

%% Save fluence map, measurement plane, dose plane    
save(strcat(fluencemap_path,fluencemap_filename),'fluencemap','beamInfo','leaf_sequence','mech_stability');    
save(strcat(meas_dose_path,meas_dose_filename),'MC');
save(strcat(plan_dose_path,plan_dose_filename),'TPS');
        
%% Begin Gamma Analysis
% -----------------------------------------------------------------------
% Finally, loop through the different gamma passing criteria.  As a default
% it will step through a distance to agreement (DTA of 1 to 5 in 1 mm
% increments, a dose_criteria threshold of 1 to 5 percent in 1 percent
% increments and a threshold value of 5 - 20 percent in 5 percent
% increments.  These can be adjused in the nested for loops as need-- the
% middle number is the step size, and the outer numbers are the starting
% and finish point.
% -----------------------------------------------------------------------

 FK_measurements_qa_results = FK_measurements_dosemetrics;
        for van_dyk_value = 1:2;
            for DTA = 1:3;
                for dose_criteria = 0.01:0.01:0.04
                    for threshold = 0.1:0.1:0.5
                        
                        [ gamma, gamma_map, avg_dose_ratio, stdev_dose_ratio ] = gamma_analysis( TPS, MC ,DTA,dose_criteria,threshold, van_dyk_value );  %#ok<ASGLU>
                        
                        % -------------------------------------------------
                        % Each cell value gives specific information about
                        % that analysis and is commented to the right of
                        % the semi-colon.
                        % ------------------------------------------------- 
                        
                        if van_dyk_value == 1;
                            van_dyk = 'ON';
                        else
                            van_dyk = 'OFF';
                        end
                        
                        data_qaresults{1,1} = DTA;
                        data_qaresults{1,2} = dose_criteria*100;
                        data_qaresults{1,3} = threshold*100;
                        data_qaresults{1,4} = van_dyk;
                        data_qaresults{1,5} = length(gamma(:,1));  %% Total amount of gamma points analyized
                        
                            passed = find(gamma(:,1)<=1);
                            num_pass = length(passed);
                            pct_pass = roundn(num_pass/length(gamma(:,1))*100,-2);
                        
                        data_qaresults{1,6} = pct_pass;
                        data_qaresults{1,7} = avg_dose_ratio;
                        data_qaresults{1,8} = stdev_dose_ratio;
                        data_qaresults{1,9} = gamma_map_path;
                        
                        
                        conn = database(dbpath,username,pwd,obj,URL);

                            gamma_map_filename = strcat(patient_ID,'-',num2str(FK_measurements_qa_results),'-',num2str(z),'.mat');
                            data_qaresults{1,10} = gamma_map_filename;
                            data_qaresults{1,11} = FK_measurements_qa_results;                          
                            insert(conn,tablename_qaresults,colnames_qaresults,data_qaresults);
        
                        close(conn) 
                        
                        save(strcat(gamma_map_path,gamma_map_filename),'gamma_map');
                        waitbar(steps / total_steps,h,sprintf('Patient %d out of %d. (%.2f Percent Complete)',i,pt_num_end,((steps / total_steps)*100)))
                        z = z + 1;
                        steps = steps + 1;
                        
                    end
                end
            end   
        end
    toc      
    movefile(source,destination)
end

  close(h)
  
end





