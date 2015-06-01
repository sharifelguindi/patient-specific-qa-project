function headerInfo = convertMapCheckHeader(headerText)

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
headerInfo.date            = [];
headerInfo.time            = [];
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
