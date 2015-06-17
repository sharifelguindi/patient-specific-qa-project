function [ ] = data_input_gui_batch(batch_path, folders, destination, dbpath)


h = waitbar(0,'Please wait...');
pt_num_start = 1;
pt_num_end = length(folders);
total_steps = (pt_num_end - pt_num_start + 1)*120;

for i = pt_num_start:pt_num_end

%% Get Patient Files
 root_path    = cell2mat(strcat(batch_path,'\',folders(i)));
 MC_filename  = dir(strcat(root_path,'\','*.txt'));

 if length(MC_filename) > 1;
    MC_filename = dir(strcat(root_path,'\','mc*.txt'));
     if length(MC_filename) > 1;
         close(h)
         h = msgbox('Measured Dose File is ambiguous, aborted loading.');
         return
     end
 end
  
 TPS_filename  = dir(strcat(root_path,'\','RD*.dcm'));
 RP_filename   = dir(strcat(root_path,'\','RP*.dcm'));
 xcl_filename  = dir(strcat(root_path,'\','*.xls'));
 
 
%% Determine all data from Excel File, if not found set defaults
 if length(xcl_filename) == 1
    xcl_file         = strcat(root_path,'\', xcl_filename.name);
    [~,~,raw]    = xlsread(xcl_file, 'MapPhan dose scaled', 'B3:D33');
       
     plan_name = cell2mat(raw(3,1));
     if isempty(plan_name) == 1 || isnumeric(plan_name) == 1
        plan_name = 'unknown';
     end
    
     dose_scaling = double(cell2mat(raw(13,2)));
     ind_C        = find(strcmp(raw,'CTX')==1);
     ind_D        = find(strcmp(raw,'DTX')==1);
     ind_A        = find(strcmp(raw,'AEX')==1);

     if isempty(ind_A) == 0
        machine_name = raw(ind_A);
     elseif isempty(ind_C) == 0
        machine_name = raw(ind_C);
     elseif isempty(ind_D) == 0
        machine_name = raw(ind_D);
     else
        machine_name = 'unknown';
     end    

     machine_name = char(machine_name);

     name = plan_name;
     name = strrep(name,'/','-');
     name = strrep(name,'\','-');
     name = strrep(name,'#','-');
     name = strrep(name,'.','-');
     name = strrep(name,':','-');
 else
     dose_scaling = 1;
     machine_name = 'unknown';
     plan_name    = 'unknown';
     name         = 'unknown';
 end    

%% Logic for uploading data based on folder contents
 if length(MC_filename) == 1 && ...
   length(TPS_filename) == 1 && ...
    length(RP_filename) == 1 

     MC_file      = strcat(root_path,'\', MC_filename.name); 
     TPS_file     = strcat(root_path,'\', TPS_filename.name);
     RP_file      = strcat(root_path,'\', RP_filename.name);
    
     data_input_gui(root_path, destination, MC_file, TPS_file, RP_file, plan_name, name, machine_name, dose_scaling, dbpath);   

 elseif length(MC_filename) == 1 && ...
       length(TPS_filename) == 1 && ...
        length(RP_filename) ~= 1 
    
     MC_file      = strcat(root_path,'\', MC_filename.name); 
     TPS_file     = strcat(root_path,'\', TPS_filename.name);
    
     data_input_measurement_only(root_path, destination, MC_file, TPS_file, plan_name, name, machine_name, dose_scaling, dbpath);
     
 elseif length(MC_filename) ~= 1 || ...
       length(TPS_filename) ~= 1 && ...
        length(RP_filename) == 1 
    
     RP_file      = strcat(root_path,'\', RP_filename.name);
     data_input_plan_only(root_path, destination, RP_file, dbpath)
    
 else
     
     return

 end

  
end





