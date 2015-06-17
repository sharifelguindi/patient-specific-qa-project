%--------------------------------------------------------------------------
% Initialize GUI (generated from Matlab GUIDE)
%--------------------------------------------------------------------------
function varargout = vmatqatool(varargin)

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @vmatqatool_OpeningFcn, ...
                       'gui_OutputFcn',  @vmatqatool_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end

function vmatqatool_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>

    % Choose default command line output for vmatqatool
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);
    
    %% Grey out undeveloped features
%     set(handles.select_batch_file_path,'Enable','off') 
%     set(handles.batch_upload_start,'Enable','off') 
%     set(handles.batch_upload_path,'Enable','off') 
    set(handles.database_cleanup,'Enable','off') 
    
function varargout = vmatqatool_OutputFcn(hObject, eventdata, handles) 

    % Get default command line output from handles structure
    varargout{1} = handles.output;

    
%--------------------------------------------------------------------------
% Function calls for selected paths in GUI
%--------------------------------------------------------------------------
function select_patient_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
 
 set(handles.upload_to_database,'Enable','on')  
 [path]       = uigetdir('J:\PhysicsDosimetry\Eclipse TPS\Patient Specific QA');
 handles.path = strcat(path,'\');
 set(handles.patient_root_path,'string',handles.path);
 h = msgbox('Validating patient folder for analysis...');  
 root_path    = handles.path;
  
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
 no_excel_flag = 0;
 
 if isempty(xcl_filename) == 1 && length(MC_filename) >= 1 && length(TPS_filename) >= 1 && length(RP_filename) >= 1 
     close(h)
     h = msgbox('No Excel Sheet Found, Please manually enter scaling factor and machine name');
     no_excel_flag = 1;
     set(handles.upload_to_database,'Enable','on')  
 elseif isempty(MC_filename) == 1 || isempty(TPS_filename) == 1 || isempty(RP_filename) == 1 || isempty(xcl_filename) == 1
     close(h)
     h = msgbox('all files not found, some features may not work');
     set(handles.upload_to_database,'Enable','off')  
 end
  
 MC_file      = strcat(root_path, MC_filename.name);
     if isempty(MC_filename) == 1
         set(handles.mc_okay_check,'string','NOT FOUND');
         set(handles.compute_gamma_analysis,'Enable','off')
         set(handles.upload_measurement_only,'Enable','off')
     else
         set(handles.mc_okay_check,'string',MC_filename.name);
         set(handles.compute_gamma_analysis,'Enable','on')
         set(handles.upload_measurement_only,'Enable','on')
     end
 
 TPS_file     = strcat(root_path, TPS_filename.name);
     if isempty(TPS_filename) == 1
         set(handles.RD_okay_check,'string','NOT FOUND');
         set(handles.compute_gamma_analysis,'Enable','off')
         set(handles.upload_measurement_only,'Enable','off')
     else
         set(handles.RD_okay_check,'string',TPS_filename.name);
         set(handles.compute_gamma_analysis,'Enable','on')
         set(handles.upload_measurement_only,'Enable','on')
     end
 
 RP_file      = strcat(root_path, RP_filename.name);
     if isempty(RP_filename) == 1
         set(handles.RP_okay_check,'string','NOT FOUND');
         set(handles.upload_plan_metrics_only,'Enable','off')
         set(handles.compute_plan_metrics,'Enable','off')
     else
         set(handles.RP_okay_check,'string',RP_filename.name);
         set(handles.upload_plan_metrics_only,'Enable','on')
         set(handles.compute_plan_metrics,'Enable','on')
     end
 
 xcl_file         = strcat(root_path, xcl_filename.name);
 handles.xcl_file = xcl_file;
 
     if isempty(xcl_filename) == 1
         set(handles.excel_okay_check,'string','NOT FOUND');
     else
         set(handles.excel_okay_check,'string',xcl_filename.name);
     end
     
 if no_excel_flag == 0
     
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
     set(handles.machine_name,'string',machine_name);
     set(handles.scaling_factor,'string',num2str(dose_scaling));
     set(handles.plan_name,'string',plan_name);
     
     guidata(hObject, handles);
     close(h)
 else
     guidata(hObject, handles);
     close(h)
 end
 
function select_destination_Callback(hObject, eventdata, handles)

    [path] = uigetdir;
    handles.path = strcat(path,'\');
    set(handles.destination_root_path,'string',handles.path);
    guidata(hObject, handles);

function select_database_path_Callback(hObject, eventdata, handles)

    [filename, pathname] = uigetfile({'*.*'},'File Selector');
        handles.database = [pathname,filename];

    set(handles.database_path,'string',handles.database);

    guidata(hObject, handles);

function select_batch_file_path_Callback(hObject, eventdata, handles)

    [path] = uigetdir('J:\PhysicsDosimetry\Eclipse TPS\Patient Specific QA');
    handles.batch_path = strcat(path,'\');
    set(handles.batch_upload_path,'string',handles.batch_path);
    d = dir(handles.batch_path);
    isub = [d(:).isdir]; %# returns logical vector
    folders = {d(isub).name}';
    folders(ismember(folders,{'.','..','ArcCHECK do not remove','Cal files','Pending Upload'})) = [];
    h = msgbox(['Folders to Upload:'; folders]);
    handles.folders = folders;
    guidata(hObject, handles);
   
%--------------------------------------------------------------------------
% Call display boxes for associated paths
%--------------------------------------------------------------------------
function destination_root_path_CreateFcn(hObject, eventdata, handles) 

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
 
function patient_root_path_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end 
    
function database_path_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function batch_upload_path_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end    
    

%--------------------------------------------------------------------------
% Function Calls for associated buttons in Matlab GUI
%--------------------------------------------------------------------------    
function compute_gamma_analysis_Callback(hObject, eventdata, handles)

   root_path = get(handles.patient_root_path,'string'); 
     MC_file = strcat(root_path, get(handles.mc_okay_check,'string'));
    TPS_file = strcat(root_path, get(handles.RD_okay_check,'string'));

     machine_name = get(handles.machine_name,'string');
     dose_scaling = str2double(get(handles.scaling_factor,'string'));
              DTA = str2double(get(handles.DTA,'string'));
    dose_criteria = str2double(get(handles.pct_diff,'string'))/100;
        threshold = str2double(get(handles.pct_threshold,'string'))/100;
      
            if (get(handles.van_dyk,'Value') == get(handles.van_dyk,'Max'))
                van_dyk = 1; %ON
                van_dyk_disp = 'ON';
            else
                van_dyk = 2; %OFF
                van_dyk_disp = 'OFF';
            end
   
[ MC, ~, ~, ~ ] = readMapCheck( MC_file );
    [ TPS_dose] = open_doseplane( TPS_file );
       TPS_dose = TPS_dose*dose_scaling;
        
    [ gamma, ~, avg_dose_ratio, stdev_dose_ratio ] = gamma_analysis( TPS_dose, MC(2:end,2:end),DTA,dose_criteria,threshold,van_dyk ); 

    axes(handles.display_graph);
    cla
    imshow(TPS_dose,[min(min(TPS_dose)) max(max(TPS_dose))]);
    colormap(gray(32));
    colormap( 1 - colormap );
    freezeColors;
    hold on
    ind = find(gamma(:,1)>1);
    scatter(gamma(ind,3),gamma(ind,2),10,'r','fill')
    xlabel('Gamma Map')
    ylabel('')

    data_qaresults{1,2} = DTA;
    data_qaresults{1,1} = 'DTA';

    data_qaresults{2,2} = dose_criteria*100;
    data_qaresults{2,1} = 'Dose Criteria';

    data_qaresults{3,2} = threshold*100;
    data_qaresults{3,1} = 'Threshold';

    data_qaresults{4,2} = van_dyk_disp;
    data_qaresults{4,1} = 'Van Dyk';

    data_qaresults{5,2} = length(gamma(:,1));  %% Total amount of gamma points analyized
    data_qaresults{5,1} = '# Points';

        passed = find(gamma(:,1)<=1);
        num_pass = length(passed);
        pct_pass = roundn(num_pass/length(gamma(:,1))*100,-2);

    data_qaresults{6,2} = pct_pass;
    data_qaresults{6,1} = '% Pass';

    data_qaresults{7,2} = avg_dose_ratio;
    data_qaresults{7,1} = 'Dose Ratio';

    data_qaresults{8,2} = stdev_dose_ratio;
    data_qaresults{8,1} = 'DR StDev';

    data_qaresults{9,2} = dose_scaling;
    data_qaresults{9,1} = 'Dose Scaling';

    data_qaresults{10,2} = machine_name;
    data_qaresults{10,1} = 'Machine Name';
    
    set(handles.display_table,'data',data_qaresults,'ColumnName',{'Parameter','Value'})
     
function compute_plan_metrics_Callback(hObject, eventdata, handles)
          
           h = msgbox('Opening Files...');
   root_path = get(handles.patient_root_path,'string'); 
     RP_file = strcat(root_path, get(handles.RP_okay_check,'string'));  
        info = dicominfo(RP_file);
    numbeams = info.FractionGroupSequence.Item_1.NumberOfBeams;
   

[ data, ~, ~, ~, mech_stability ] = calc_fluence_map(RP_file);  

data_planmetrics{1,1}  = numbeams;
data_planmetrics{1,2}  = data.PLW;
data_planmetrics{1,3}  = data.PA;
data_planmetrics{1,4}  = data.PM;
data_planmetrics{1,5}  = data.PI;
data_planmetrics{1,6}  = data.PAGW;
data_planmetrics{1,7}  = data.totalMU;
data_planmetrics{1,8}  = data.modulation_type;
data_planmetrics{1,9}  = data.field_size_X;
data_planmetrics{1,10} = data.field_size_Y;
data_planmetrics{1,11} = mech_stability.plan_mean_deg_MU;
data_planmetrics{1,12} = mech_stability.plan_bankA_mm_MU;
data_planmetrics{1,13} = mech_stability.plan_bankB_mm_MU;

data_planmetrics{1,14} = data.PI + 3*(((mech_stability.plan_bankA_mm_MU + mech_stability.plan_bankB_mm_MU)/2)*(mech_stability.plan_mean_deg_MU));


set(findobj(h,'Tag','MessageBox'),'String','Fetching Current Database Values...')
                  dbpath = get(handles.database_path,'string');
                username = '';
                     pwd = '';
                     obj = 'org.sqlite.JDBC';
                     URL = ['jdbc:sqlite:',dbpath];
                    conn = database(dbpath,username,pwd,obj,URL);    


eval(['query = fetch(conn,''SELECT patient_ID, dose_scaling, mean_target_dose,', ...
                                  'mean_target_gradient, mean_pneumbra_gradient, mean_lowdose_gradient, mean_lowdose_dose,',...
                                  'target_dose_diff, target_dose_stdev, target_dose_numpoints, pneumbra_dose_diff, pneumbra_dose_stdev,', ...
                                  'pneumbra_dose_numpoints, low_dose_diff, low_dose_stdev, low_dose_numpoints,',...
                                  'numbeams, PLW, PA, PAGW, PI, PM, totalMU, field_size_X, field_size_Y, degree_per_MU, bankA_mm_per_MU, bankB_mm_per_MU,',... 
                                  'dta, dose_criteria, threshold, numpts_analyzed, avg_dose_ratio, stdev_dose_ratio, gpr ',...
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
               'AND machine_name = "CTX" ',...
               'AND threshold = 10 ',...
               'AND dta = 2 ',...
               'AND dose_criteria = 1 ',...
               ''');'])

data = cell2mat(query);

close(conn)

if isempty(data) == 1
    data = transpose(data_planmetrics);
    data(:,2) = data;
    data{1,1} = 'Number of Beams';
    data{2,1} = '% MU Large Leaves';
    data{3,1} = 'Plan Area';
    data{4,1} = 'Plan Modulation';
    data{5,1} = 'Plan Irregularity';
    data{6,1} = 'Plan Area Gantry Weighted';
    data{7,1} = 'Total MU';
    data{8,1} = 'Modulation Type';
    data{9,1} = 'FS X';
    data{10,1} = 'FS Y';
    data{11,1} = 'MU/degree';
    data{12,1} = 'Bank A mm/MU';
    data{13,1} = 'Bank B mm/MU';
    data{14,1} = 'Figure of Merit';
    data{15,1} = 'Estimated GPR';
    data{15,2} = 'No Data Avail';
    set(handles.display_table,'data',data,'ColumnName',{'Parameter','Value'})
    close(h)
    return
end

cla(handles.display_graph,'reset')
axes(handles.display_graph);
unfreezeColors;
cla

PI_leafspeed(:,1) = data(:,27).*data(:,26);
C0 = 1;
C1 = 3;
classifier_values(:,1) = C0.*(((data(:,21)))) + C1.*(PI_leafspeed(:,1));
x = data(:,35);
y = classifier_values(:,1);

scatter(x,y,'fill')
hold on
p = polyfit(y,x,1);
ynew = data_planmetrics{1,14};
xfit = polyval(p,ynew);
scatter(xfit,ynew,'r','fill');
xlabel('GPR (%)')
ylabel('Figure of Merit')
data_planmetrics{1,15} = xfit;

data = transpose(data_planmetrics);
data(:,2) = data;

data{1,1} = 'Number of Beams';
data{2,1} = '% MU Large Leaves';
data{3,1} = 'Plan Area';
data{4,1} = 'Plan Modulation';
data{5,1} = 'Plan Irregularity';
data{6,1} = 'Plan Area Gantry Weighted';
data{7,1} = 'Total MU';
data{8,1} = 'Modulation Type';
data{9,1} = 'FS X';
data{10,1} = 'FS Y';
data{11,1} = 'MU/degree';
data{12,1} = 'Bank A mm/MU';
data{13,1} = 'Bank B mm/MU';
data{14,1} = 'Figure of Merit';
data{15,1} = 'Estimated GPR';
            
set(handles.display_table,'data',data,'ColumnName',{'Parameter','Value'})
close(h)

function upload_plan_metrics_only_Callback(hObject, eventdata, handles)
    
       root_path = get(handles.patient_root_path,'string'); 
     destination = get(handles.destination_root_path,'string'); 
          dbpath = get(handles.database_path,'string');
         RP_file = strcat(root_path, get(handles.RP_okay_check,'string'));  

 data_input_plan_only(root_path, destination, RP_file, dbpath)

function upload_measurement_only_Callback(hObject, eventdata, handles)
      
       root_path = get(handles.patient_root_path,'string'); 
     destination = get(handles.destination_root_path,'string'); 
          dbpath = get(handles.database_path,'string');
         MC_file = strcat(root_path, get(handles.mc_okay_check,'string'));
        TPS_file = strcat(root_path, get(handles.RD_okay_check,'string'));
        
       plan_name = get(handles.plan_name,'string');
       machine_name = get(handles.machine_name,'string');
    dose_scaling = str2double(get(handles.scaling_factor,'string'));
    
     name = plan_name;
     name = strrep(name,'/','-');
     name = strrep(name,'\','-');
     name = strrep(name,'#','-');
     name = strrep(name,'.','-');
     name = strrep(name,':','-');
   
 data_input_measurement_only(root_path, destination, MC_file, TPS_file, plan_name, name, machine_name, dose_scaling, dbpath);       
        
function upload_to_database_Callback(hObject, eventdata, handles)

       root_path = get(handles.patient_root_path,'string'); 
     destination = get(handles.destination_root_path,'string'); 
          dbpath = get(handles.database_path,'string');
         RP_file = strcat(root_path, get(handles.RP_okay_check,'string'));
         MC_file = strcat(root_path, get(handles.mc_okay_check,'string'));
        TPS_file = strcat(root_path, get(handles.RD_okay_check,'string'));
       plan_name = get(handles.plan_name,'string');
    machine_name = get(handles.machine_name,'string');
    dose_scaling = str2double(get(handles.scaling_factor,'string'));
    
     name = plan_name;
     name = strrep(name,'/','-');
     name = strrep(name,'\','-');
     name = strrep(name,'#','-');
     name = strrep(name,'.','-');
     name = strrep(name,':','-');
   

    data_input_gui(root_path, destination, MC_file, TPS_file, RP_file, plan_name, name, machine_name, dose_scaling, dbpath);                 
    
function batch_upload_start_Callback(hObject, eventdata, handles)

  batch_path = get(handles.batch_upload_path,'string'); 
 destination = get(handles.destination_root_path,'string'); 
      dbpath = get(handles.database_path,'string');
     folders = handles.folders; 
 data_input_gui_batch(batch_path, folders, destination, dbpath);
           
function database_cleanup_Callback(hObject, eventdata, handles)

    DatabaseCleanup
  
      
%--------------------------------------------------------------------------
% GUI Items that display relevant text input/output
%--------------------------------------------------------------------------     
function DTA_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function DTA_Callback(hObject, eventdata, handles)

function pct_diff_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function pct_diff_Callback(hObject, eventdata, handles)

function pct_threshold_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function pct_threshold_Callback(hObject, eventdata, handles)

function scaling_factor_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function scaling_factor_Callback(hObject, eventdata, handles)

function machine_name_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end    
    
function machine_name_Callback(hObject, eventdata, handles)    
    
function plan_name_Callback(hObject, eventdata, handles)

function plan_name_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
