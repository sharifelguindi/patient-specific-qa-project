function [] = data_input_machine_scaled_measurements()

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
        data_measurement = cell(1,8);
          data_qaresults = cell(1,11);
             format_time = 'yyyy-mm-dd HH:MM:SS';

                  warning('off','all')
                  
                    dbpath = 'J:\PhysicsDosimetry\Eclipse TPS\Lists or Rosters\Database\imrtqa';
                  username = '';
                       pwd = '';
                       obj = 'org.sqlite.JDBC';
                       URL = 'jdbc:sqlite:J:\PhysicsDosimetry\Eclipse TPS\Lists or Rosters\Database\imrtqa';             
   
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
                         
            plan_dose_path = 'J:\PhysicsDosimetry\Eclipse TPS\Lists or Rosters\Database\plan_dose\';
            meas_dose_path = 'J:\PhysicsDosimetry\Eclipse TPS\Lists or Rosters\Database\meas_dose\';
            gamma_map_path = 'J:\PhysicsDosimetry\Eclipse TPS\Lists or Rosters\Database\gamma_map\';
         

h = waitbar(0,'Please wait...');


conn = database(dbpath,username,pwd,obj,URL);

eval(['query = fetch(conn,''SELECT RTplanID, plan_dose_path, plan_dose_filename, meas_dose_path, meas_dose_filename, machine_name, patient_ID, dose_scaling ', ...
               'FROM RTplans ', ...
               'JOIN measurements ', ...
               'JOIN qa_results ', ...
               'JOIN planmetrics ', ...
               'JOIN dosemetrics ', ...
               'WHERE RTplanID = FK_RTplans_measurements ',...
               ' AND measurementID = FK_measurements_qa_results ',...
               ' AND measurementID = FK_measurements_dosemetrics ',...
               ' AND RTplanID = FK_RTplans_planmetrics ',...
               'AND van_dyk = "ON" ',...
               'AND modulation_type = "VMAT" ',...
               'AND threshold = 50 ',...
               'AND dta = 2 ',...
               'AND dose_criteria = 1 ',...
               'AND patient_ID IS NOT 68148766 ',...
               'AND patient_ID IS NOT 77827376 ',...
               ''');'])
           
close(conn);
total_steps = (length(query))*120;
for i = 1:length(query)
    
    tic;
    z = 1;

    load([cell2mat(query(i,2)),cell2mat(query(i,3))]);
    load([cell2mat(query(i,4)),cell2mat(query(i,5))]);
    RTplanID = query(i,1);
    patient_ID = cell2mat(query(i,7));
    dose_scaling = cell2mat(query(i,8));
    t = now;
    instance_UID = datestr(t,format_time);
    date_time_stamp = strrep(instance_UID,' ','');
    date_time_stamp = strrep(date_time_stamp,':','');
    
        if strcmp(cell2mat(query(1,6)),'AEX') == 1
            MC = MC*(0.9859);
            machine_name = 'AEX_scaled';
        elseif strcmp(cell2mat(query(1,6)),'CTX') == 1
            MC = MC*(1.0009);
            machine_name = 'CTX_scaled';
        elseif strcmp(cell2mat(query(1,6)),'DTX') == 1
            MC = MC*(1.0198);
            machine_name = 'DTX_scaled';
        else
            machine_name = 'unknown';
        end         
        
   %% Save plan and meas pathnames
        meas_dose_filename = strcat(num2str(patient_ID),'-scaled-','meas','-',date_time_stamp,'.mat');
        plan_dose_filename = strcat(num2str(patient_ID),'-scaled-','plan','-',date_time_stamp,'.mat');
  
   %% Pull Background information (only if not composite text file)
          okay = 0;
          try
            [mapCheckArray,~] = readMapCheck( [cell2mat(query(1,4)),cell2mat(query(1,5))]);
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
 
   
%% Database Insert


        FK_RTplans_measurements = int64(cell2mat(RTplanID));

    
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

                            gamma_map_filename = strcat(num2str(patient_ID),'-',num2str(FK_measurements_qa_results),'-',num2str(z),'.mat');
                            data_qaresults{1,10} = gamma_map_filename;
                            data_qaresults{1,11} = FK_measurements_qa_results;                          
                            insert(conn,tablename_qaresults,colnames_qaresults,data_qaresults);
        
                        close(conn) 
                        
                        waitbar(steps / total_steps,h,sprintf('Patient %d out of %d. (%.2f Percent Complete)',i,length(query),((steps / total_steps)*100)))
                        z = z + 1;
                        steps = steps + 1;
                        
                        save(strcat(gamma_map_path,gamma_map_filename),'gamma_map');

                    end
                end
            end   
        end
    toc      
    
end


  close(h)

  
end




