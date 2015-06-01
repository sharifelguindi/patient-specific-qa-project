function varargout = DatabaseCleanup(varargin)

 
%% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DatabaseCleanup_OpeningFcn, ...
                   'gui_OutputFcn',  @DatabaseCleanup_OutputFcn, ...
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

function DatabaseCleanup_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DatabaseCleanup (see VARARGIN)

% Choose default command line output for DatabaseCleanup
    handles.output = hObject;

% Update handles structure
    guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = DatabaseCleanup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function patient_ID_Callback(hObject, eventdata, handles) %#ok<*DEFNU,*INUSD>

% --- Executes during object creation, after setting all properties.
function patient_ID_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
% Finds patient in Database and populates corresponding drop down lists
% and tables
function look_up_Callback(hObject, eventdata, handles)

 dbpath = get(handles.database_path,'string');
                username = '';
                     pwd = '';
                     obj = 'org.sqlite.JDBC';
                     URL = ['jdbc:sqlite:',dbpath];
                     
  
 patient_ID = get(handles.patient_ID,'string');
 
 conn = database(dbpath,username,pwd,obj,URL); 
     eval(['query_patient = fetch(conn,''SELECT plan_name, RTplanID ',...
           'FROM RTplans ',...
           'WHERE patient_ID = ' num2str(patient_ID) '',...
           ''');'])
 close(conn)

 if isempty(query_patient) == 1 %#ok<*NODEF>
     
     set(handles.plan_list,'string','No Patient Found');
     set(handles.measurement_list,'string','No Patient Found');
     set(handles.plan_metric_list,'string','No Patient Found');
     
 else
     
     conn = database(dbpath,username,pwd,obj,URL); 
     
          eval(['query_measurements = fetch(conn,''SELECT plan_name, measurementID, RTplanID ',...
           'FROM RTplans ',...
           'JOIN measurements ',...
           'WHERE RTplanID = FK_RTplans_measurements ',...
           'AND patient_ID = ' num2str(patient_ID) '',...
           ''');'])
     
     
         eval(['query_planmetrics = fetch(conn,''SELECT plan_name, planmetricID, RTplanID ',...
               'FROM RTplans ',...
               'JOIN planmetrics ',...
               'WHERE RTplanID = FK_RTplans_planmetrics ',...
               'AND patient_ID = ' num2str(patient_ID) '',...
               ''');'])
           
     close(conn)
     
     if isempty(query_measurements) == 1 && isempty(query_planmetrics) == 1
         
            set(handles.plan_list,'string',query_patient(:,2));
            set(handles.measurement_list,'string','No Measurements');
            set(handles.plan_metric_list,'string','No Plan Metrics');
            set(handles.info_table,'data',transpose(query_patient));
            handles.current_query = query_patient;
            handles.case_type = 0;
              
     elseif isempty(query_measurements) == 1 && isempty(query_planmetrics) ~= 1
         
            set(handles.plan_list,'string',query_planmetrics(:,3));
            set(handles.measurement_list,'string','No Measurements');
            set(handles.plan_metric_list,'string',query_planmetrics(:,2));
            
            conn = database(dbpath,username,pwd,obj,URL); 

                eval(['query_plan = fetch(conn,''SELECT plan_name, study_date, numbeams, ',...
                      'PM, PI, totalMU, modulation_type, field_size_x, field_size_y ',... 
                      'FROM RTplans ',...
                      'JOIN planmetrics ',...
                      'WHERE RTplanID = ' num2str(query_patient{1,3}) '',...
                      ' AND planmetricID = ' num2str(query_planmetrics{1,2}) '',...
                      ''');'])

            close(conn)
            
            data = transpose(query_plan);
            data(:,2) = data;
            data{1,1} = 'Plan Name';
            data{2,1} = 'Measurement Date';
            data{3,1} = 'Number of Beams';
            data{4,1} = 'Plan Modulation';
            data{5,1} = 'Plan Irregularity';
            data{6,1} = 'Total MU';
            data{7,1} = 'Modulation Type';
            data{8,1} = 'FS X';
            data{9,1} = 'FS Y';
            
            handles.current_query = query_planmetrics;
            handles.case_type = 1;
            set(handles.info_table,'data',data);
            
     elseif isempty(query_measurements) ~= 1 && isempty(query_planmetrics) == 1
         
            set(handles.plan_list,'string',query_measurements(:,3));
            set(handles.measurement_list,'string',query_measurements(:,2));
            set(handles.plan_metric_list,'string','No Plan Metrics');
            
            conn = database(dbpath,username,pwd,obj,URL); 

                eval(['query_plan = fetch(conn,''SELECT plan_name, study_date, machine_name, dose_scaling ',...
                      'FROM RTplans ',...
                      'JOIN measurements ',...
                      'WHERE RTplanID = ' num2str(query_measurements{1,3}) '',...
                      ' AND measurementID = ' num2str(query_measurements{1,2}) '',...
                      ''');'])

            close(conn)
            
                        data = transpose(query_plan);
            data(:,2) = data;
            data{1,1} = 'Plan Name';
            data{2,1} = 'Measurement Date';
            data{3,1} = 'Machine Name';
            data{4,1} = 'Dose Scaling';
            
            handles.current_query = query_measurements;
            handles.case_type = 2;
            set(handles.info_table,'data',data);
            
     else       
         
            set(handles.plan_list,'string',query_measurements(:,3));
            set(handles.measurement_list,'string',query_measurements(:,2));
            set(handles.plan_metric_list,'string',query_planmetrics(:,2));
            
            conn = database(dbpath,username,pwd,obj,URL); 

                eval(['query_plan = fetch(conn,''SELECT plan_name, study_date, machine_name, dose_scaling, ',...
                      'numbeams, PM, PI, totalMU, modulation_type, field_size_x, field_size_y ',... 
                      'FROM RTplans ',...
                      'JOIN measurements ',...
                      'JOIN planmetrics ',...
                      'WHERE RTplanID = ' num2str(query_measurements{1,3}) '',...
                      ' AND measurementID = ' num2str(query_measurements{1,2}) '',...
                      ' AND planmetricID = ' num2str(query_planmetrics{1,2}) '',...
                      ''');'])

             close(conn)
             
            data = transpose(query_plan);
            data(:,2) = data;
            data{1,1} = 'Plan Name';
            data{2,1} = 'Measurement Date';
            data{3,1} = 'Machine Name';
            data{4,1} = 'Dose Scaling';
            data{5,1} = 'Number of Beams';
            data{6,1} = 'Plan Modulation';
            data{7,1} = 'Plan Irregularity';
            data{8,1} = 'Total MU';
            data{9,1} = 'Modulation Type';
            data{10,1} = 'FS X';
            data{11,1} = 'FS Y';
            handles.current_query = query_measurements;
            handles.plan_metrics_query = query_planmetrics;
            handles.case_type = 3;
            set(handles.info_table,'data',data);
     end
 end
 
 guidata(hObject,handles);
 
% --- Executes on button press in delete_measurement.
function delete_measurement_Callback(hObject, eventdata, handles)

    contents = cellstr(get(handles.measurement_list,'String'));
    current_value_meas = contents{get(handles.measurement_list,'Value')};

     dbpath = get(handles.database_path,'string');
                    username = '';
                         pwd = '';
                         obj = 'org.sqlite.JDBC';
                         URL = ['jdbc:sqlite:',dbpath];

     conn = database(dbpath,username,pwd,obj,URL); 

            eval(['query_measurements = fetch(conn,''SELECT meas_dose_path, meas_dose_filename, plan_dose_path, plan_dose_filename ',...
               'FROM measurements ',...
               'WHERE measurementID = ' current_value_meas '',...
               ''');'])

            eval(['query_qa_results = fetch(conn,''SELECT qa_resultID, gamma_map_path, gamma_map_filename ',...
               'FROM measurements ',...
               'JOIN qa_results ',...
               'WHERE measurementID = ' current_value_meas '',...
               ' AND measurementID = FK_measurements_qa_results',...
               ''');'])

            eval(['query_dosemetrics = fetch(conn,''SELECT dosemetricID ',...
               'FROM measurements ',...
               'JOIN dosemetrics ',...
               'WHERE measurementID = ' current_value_meas '',...
               ' AND measurementID = FK_measurements_dosemetrics',...
               ''');'])

       close(conn)    

    conn = database(dbpath,username,pwd,obj,URL); 

     for i = 1:length(query_qa_results)


         curs = exec(conn,['DELETE FROM qa_results WHERE ',...
                     'qa_resultID = ' num2str(cell2mat(query_qa_results(i,1)))]);
         current_file = [cell2mat(query_qa_results(i,2)),cell2mat(query_qa_results(i,3))];
         delete(current_file);
         close(curs)

     end

     for i = 1:length(query_dosemetrics)

         curs = exec(conn,['DELETE FROM dosemetrics WHERE ',...
                     'dosemetricID = ' num2str(cell2mat(query_dosemetrics(i)))]);
         close(curs)
     end

      curs = exec(conn,['DELETE FROM measurements WHERE ',...
                     'measurementID = ' current_value_meas]);
      current_file = [cell2mat(query_measurements(1,1)),cell2mat(query_measurements(1,2))];
      delete(current_file);
      current_file = [cell2mat(query_measurements(1,3)),cell2mat(query_measurements(1,4))];
      delete(current_file);

      close(curs)

    close(conn)

% --- Executes on selection change in measurement_list.
function measurement_list_Callback(hObject, eventdata, handles)
    
    contents = cellstr(get(handles.measurement_list,'String'));
    current_value = contents{get(handles.measurement_list,'Value')};

    query = handles.current_query;

    current_plans = cell2mat(query(:,2));

    ind_meas = current_plans==str2double(current_value);

    set(handles.measurement_list,'string',query(ind_meas,2));
    
    case_type = handles.case_type;
    
    dbpath = get(handles.database_path,'string');
    username = '';
    pwd = '';
    obj = 'org.sqlite.JDBC';
    URL = ['jdbc:sqlite:',dbpath];
    
   conn = database(dbpath,username,pwd,obj,URL); 
    
    switch case_type
        case 0
            disp('No Data')
        case 1
            disp('No Data')
        case 2
            
           eval(['query_plan = fetch(conn,''SELECT plan_name, study_date, machine_name, dose_scaling ',...
                      'FROM RTplans ',...
                      'JOIN measurements ',...
                      'WHERE RTplanID = ' num2str(current_value) '',...
                      ' AND measurementID = ' num2str(query{ind_meas,2}) '',...
                      ''');'])

            close(conn)
            
            data = transpose(query_plan);
            data(:,2) = data;
            data{1,1} = 'Plan Name';
            data{2,1} = 'Measurement Date';
            data{3,1} = 'Machine Name';
            data{4,1} = 'Dose Scaling';
            
            set(handles.info_table,'data',data);
            
        case 3
            
            query_planmetrics = handles.plan_metrics_query;
            eval(['query_plan = fetch(conn,''SELECT plan_name, study_date, machine_name, dose_scaling, ',...
                  'numbeams, PM, PI, totalMU, modulation_type, field_size_x, field_size_y ',... 
                  'FROM RTplans ',...
                  'JOIN measurements ',...
                  'JOIN planmetrics ',...
                  'WHERE RTplanID = ' num2str(current_value) '',...
                  ' AND measurementID = ' num2str(query{ind_meas,2}) '',...
                  ' AND planmetricID = ' num2str(query_planmetrics{ind_meas,2}) '',...
                  ''');'])

             close(conn)
             
            data = transpose(query_plan);
            data(:,2) = data;
            data{1,1} = 'Plan Name';
            data{2,1} = 'Measurement Date';
            data{3,1} = 'Machine Name';
            data{4,1} = 'Dose Scaling';
            data{5,1} = 'Number of Beams';
            data{6,1} = 'Plan Modulation';
            data{7,1} = 'Plan Irregularity';
            data{8,1} = 'Total MU';
            data{9,1} = 'Modulation Type';
            data{10,1} = 'FS X';
            data{11,1} = 'FS Y';
            set(handles.info_table,'data',data);
    end
     
    
% --- Executes during object creation, after setting all properties.
function measurement_list_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% --- Executes on button press in delete_plan_and_measurements.
function delete_plan_and_measurements_Callback(hObject, eventdata, handles)

% --- Executes on button press in delete_patient.
function delete_patient_Callback(hObject, eventdata, handles)

% --- Executes on selection change in plan_list.
function plan_list_Callback(hObject, eventdata, handles)

    contents = cellstr(get(handles.plan_list,'String'));
    current_value = contents{get(handles.plan_list,'Value')};

    query = handles.current_query;

    current_plans = cell2mat(query(:,3));

    ind_meas = current_plans==str2double(current_value);
    set(handles.measurement_list,'string',query(ind_meas,2));

    dbpath = get(handles.database_path,'string');
         username = '';
         pwd = '';
         obj = 'org.sqlite.JDBC';
         URL = ['jdbc:sqlite:',dbpath];

         conn = database(dbpath,username,pwd,obj,URL); 
         
           eval(['query_plan = fetch(conn,''SELECT plan_name, study_date, machine_name, dose_scaling, target_dose_diff ',...
                      'FROM RTplans ',...
                      'JOIN measurements ',...
                      'JOIN dosemetrics ',...
                      'WHERE RTplanID = ' num2str(current_value) '',...
                      ' AND measurementID = ' num2str(query{ind_meas,2}) '',...
                      ' AND measurementID = FK_measurements_dosemetrics',...
                      ''');'])

            close(conn)
            
            data = transpose(query_plan);
            data(:,2) = data;
            data{1,1} = 'Plan Name';
            data{2,1} = 'Measurement Date';
            data{3,1} = 'Machine Name';
            data{4,1} = 'Dose Scaling';
            data{5,1} = 'Target Dose Diff';
            
            set(handles.info_table,'data',data);

% --- Executes during object creation, after setting all properties.
function plan_list_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function database_path_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function database_path_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% --- Executes on button press in select_database.
function select_database_Callback(hObject, eventdata, handles)

    [filename, pathname] = uigetfile({'*.*'},'File Selector');
        handles.database = [pathname,filename];

    set(handles.database_path,'string',handles.database);

    guidata(hObject, handles);

% --- Executes on selection change in plan_metric_list.
function plan_metric_list_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function plan_metric_list_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
