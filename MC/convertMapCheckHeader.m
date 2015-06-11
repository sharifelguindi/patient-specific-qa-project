function headerInfo = convertMapCheckHeader(headerText, L)



headerInfo.fileVersion     = strtok(headerText(3,:),' ');
headerInfo.fileRevision    = strtrim(strtok(headerText(4,:),'File Revision:'));
headerInfo.fileType        = strtok(headerText(5,:),' ');
headerInfo.deviceID        = strtok(headerText(7,:),'   ');
headerInfo.firmwareVersion = num2str(str2double(strtok(headerText(10,:),'Firmware Version:')));
headerInfo.diodeType       = num2str(str2double(strtok(headerText(12,:),'Diode Type:')));
headerInfo.Temperature     = [];
headerInfo.inclineTilt     = str2double(strtok(headerText(14,:),'Inclinometer Tilt:'));
headerInfo.inclineRot      = str2double(strtok(headerText(15,:),'Inclinometer Rotation:'));
headerInfo.bgThresh        = str2double(strtok(headerText(16,:),'Background Threshold:'));


if strcmp(headerInfo.fileType,'Measured') == 1 && strcmp(headerInfo.deviceID,'1177') == 1
    
    measDateTime               = strrep(headerText(19,:),'Time:',' ');
    measDateTime               = strrep(measDateTime,':','');
    headerInfo.measDateTime    = strtrim(strtok(measDateTime,'Date:'));
    headerInfo.serialNum       = str2double(strtok(headerText(20,:),'Serial No:'));
    headerInfo.overrangeErr    = str2double(strtok(headerText(22,:),'Overrange Error:'));

    colonLoc                   = strfind(headerText(24,:),':');
    headerInfo.arrayCalFile    = strtrim(headerText(24,colonLoc+1:end));

    headerInfo.dosePerCount    = str2double(strtok(headerText(26,:),'Dose per Count:'));

    [energy,doseCal]           = strtok(headerText(27,:),'Dose Info:');
    headerInfo.energy          = strtrim(energy);
    headerInfo.doseCal         = strtrim(doseCal);

    headerInfo.doseIDDC        = str2double(strtok(headerText(28,:),'Dose IDDC:'));
    headerInfo.orientation     = str2double(strtok(headerText(32,:),'Orientation:'));
    headerInfo.numRows         = str2double(strtok(headerText(34,:),'Rows:'));
    headerInfo.numCols         = str2double(strtok(headerText(35,:),'Cols:'));
    headerInfo.caxX            = str2double(strtok(headerText(36,:),'CAX X:'));
    headerInfo.caxY            = str2double(strtok(headerText(37,:),'CAX Y:'));
    headerInfo.devPosQA        = str2double(strtok(headerText(39,:),'Device Position QA:'));

    shiftXmm                   = strtrim(strtok(headerText(40,:),'Shift X:'));
    headerInfo.shiftXmm        = str2double(shiftXmm(1:end-3));
    shiftYmm                   = strtrim(strtok(headerText(41,:),'Shift Y:'));
    headerInfo.shiftYmm        = str2double(shiftYmm(1:end-3));
    rotationDeg                = strtrim(strtok(headerText(42,:),'Rotation:'));
    headerInfo.rotationDeg     = str2double(rotationDeg(1:end-3));
    
elseif strcmp(headerInfo.fileType,'Composite') == 1 && strcmp(headerInfo.deviceID,'1177') == 1
    
    comp_length = 0;
    
    for ii = 20:L
        if strcmp(headerText(ii,1:5),'Date:')
            comp_length = ii - 19;
            date_ind = ii;
        end
    end
    
    measDateTime               = strrep(headerText(date_ind,:),'Time:',' ');
    measDateTime               = strrep(measDateTime,':','');
    headerInfo.measDateTime    = strtrim(strtok(measDateTime,'Date:'));
    headerInfo.serialNum       = str2double(strtok(headerText(20+comp_length,:),'Serial No:'));
    headerInfo.overrangeErr    = str2double(strtok(headerText(22+comp_length,:),'Overrange Error:'));

    colonLoc                   = strfind(headerText(24+comp_length,:),':');
    headerInfo.arrayCalFile    = strtrim(headerText(24+comp_length,colonLoc+1:end));

    headerInfo.dosePerCount    = str2double(strtok(headerText(26+comp_length,:),'Dose per Count:'));

    [energy,doseCal]           = strtok(headerText(27+comp_length,:),'Dose Info:');
    headerInfo.energy          = strtrim(energy);
    headerInfo.doseCal         = strtrim(doseCal);

    headerInfo.doseIDDC        = str2double(strtok(headerText(28+comp_length,:),'Dose IDDC:'));
    headerInfo.orientation     = str2double(strtok(headerText(32+comp_length,:),'Orientation:'));
    headerInfo.numRows         = str2double(strtok(headerText(34+comp_length,:),'Rows:'));
    headerInfo.numCols         = str2double(strtok(headerText(35+comp_length,:),'Cols:'));
    headerInfo.caxX            = str2double(strtok(headerText(36+comp_length,:),'CAX X:'));
    headerInfo.caxY            = str2double(strtok(headerText(37+comp_length,:),'CAX Y:'));
    headerInfo.devPosQA        = str2double(strtok(headerText(39+comp_length,:),'Device Position QA:'));

    shiftXmm                   = strtrim(strtok(headerText(40+comp_length,:),'Shift X:'));
    headerInfo.shiftXmm        = str2double(shiftXmm(1:end-3));
    shiftYmm                   = strtrim(strtok(headerText(41+comp_length,:),'Shift Y:'));
    headerInfo.shiftYmm        = str2double(shiftYmm(1:end-3));
    rotationDeg                = strtrim(strtok(headerText(42+comp_length,:),'Rotation:'));
    headerInfo.rotationDeg     = str2double(rotationDeg(1:end-3));
    
end
    
    
    
    
    