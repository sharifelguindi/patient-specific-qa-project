function [ ] = data_input_measurement_only(root_path, destination, MC_file, TPS_file, plan_name, name, machine_name, dose_scaling, dbpath)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%                    Declare Global Variables for data input                     %%%%%%%%%%%%%%%%                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        h = waitbar(0,'Please wait...');       
             data_RTplan = cell(1,6);
        data_measurement = cell(1,8);
          data_qaresults = cell(1,11);
             format_time = 'yyyy-mm-dd HH:MM:SS';
                 
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
                         
            C = strsplit(dbpath,'\');
            D = C(1,1:end-1);
            pathname = strjoin(D,'\');
            plan_dose_path = [pathname,'\plan_dose\'];
            meas_dose_path = [pathname,'\meas_dose\'];
            gamma_map_path = [pathname,'\gamma_map\'];

 [ MC, mapCheckArray, ~, ~ ] = readMapCheck( MC_file );
   MC                        = MC(2:end,2:end);
        
   [ TPS ] = open_doseplane( TPS_file );
     TPS   = TPS*dose_scaling;
                   
    %% Pull DICOM information
    
             info = dicominfo(TPS_file);
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
        background = mapCheckArray(:,3:end,1);
               ind = find(background>0);
   
   if isempty(ind) == 1
       background_mean  = 0;
       background_stdev = 0;
   else
       background_mean = mean(background(ind));
       background_stdev = std(background(ind));
   end
        
    waitbar(0.25,h,sprintf('Calculating Dose Metrics...'))
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
        
        conn = database(dbpath,username,pwd,obj,URL);
              eval(['RTplanID = fetch(conn,''SELECT RTplanID FROM RTplans WHERE plan_UID=','"',plan_UID_plan,'"',''');']);
              FK_RTplans_measurements = int64(cell2mat(RTplanID));
        close(conn)

      else
          
        msgbox('Plan information is already in database');
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
    data_measurement{1,10}= background_stdev;
    
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
z = 1;
 waitbar(0.5,h,sprintf('Computing Gamma Analysis Data'))
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
                        z = z + 1;
                        waitbar(0.5 + (z/240),h,sprintf('Computing Gamma Analysis Data'))
                        
                    end
                end
            end   
        end     
    movefile(root_path,destination)
    waitbar(1,h,sprintf('Data Input Complete'))
    pause(1)
    close(h)
  
end





