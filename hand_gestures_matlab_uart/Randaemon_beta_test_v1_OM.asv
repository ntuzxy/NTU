fclose(uart);

% configure and open serial port
clear all;
clc;
close all;
% uart=serial('COM8','BaudRate',4800,'DataBits',8,'StopBits',1);%creat a serial port object
uart=serial('COM17','BaudRate',9600,'DataBits',8,'StopBits',1);%creat a serial port object
% uart=serial('COM10','BaudRate',9600,'DataBits',8,'StopBits',1);%creat a
% serial port object

% get(com6,{'Type','Name','Port','BaudRate','DataBits','FlowControl','Parity','StopBits'})
% fclose(uart);
fopen(uart);% connect the object to device
%
start_byte_1=hex2dec('FE');
start_byte_2=hex2dec('3F');
end_byte_1=hex2dec('FC');
end_byte_2=hex2dec('1F');
MAX_PacLen=256;

%% initiation

% file system
PC=0; %1 for desktop, 0 for laptop
if PC
%     DataPosition='D:\Dropbox\OK-AMS035-Oct13\20140609\';
    DataPosition='D:\Dropbox\Y\decoder\Randaemon_beta\EventData\';
    SavePosition='D:\Dropbox\Y\decoder\Randaemon_beta\Results\';
else
%     DataPosition='C:Users\ChenYi\Dropbox\OK-AMS035-Oct13\20140609\';
    DataPosition='C:\Users\Chen Yi\Dropbox\CY\decoder\Randaemon_beta\EventData\';
    SavePosition='C:\Users\Chen Yi\Dropbox\CY\decoder\Randaemon_beta\Results\';
end
% task configuration
TrainMode=1; % 1 for OM, 2 for MC, 3 for combined
TimeResolution=0.2e-3;
SampleLength=180e-3/0.2e-3;
OperationPrd=20e-3;
TimeNEU=10e-3;
TimeSettle=5e-3;
N_ReadOut=101;
sel_ReadOut_2PC=[2:101];
N_HLN=60;

Monkey='K';
NumberOfNeurons=40;
Distri=1;
N_Moves=12;

% spi and switch
sel_input=[];  % select among 0-127
N_delay=0;
bias_current=6; % 0-63
% sel_output=[0:127]; % select among 0-127

%%%%%%%%%%%%%%% output channel randomly selected %%%%%%%%%%%
% [sel_output,~]=RandDistr(1:127,N_HLN-1);
% sel_output=[0 sel_output];
% save(strcat(SavePosition,'OutputChannelSelection'),'sel_output');

load(strcat(SavePosition,'OutputChannelSelection'));
%%%%%%%%%%%%%%% output channel randomly selected %%%%%%%%%%%

Bin_out=zeros(1,128);
Bin_out(sel_output+1)=1;

RES=4;
SDL=0;
CA=2;CB=2;
ext_ctrl=0;
active=0;
mode=0;

%
%% spi
if N_delay==1
    load(strcat(DataPosition,DataFile));
    sel_input=input_ch_set{1};
end
if N_delay==2
    load(strcat(DataPosition,DataFile));
    sel_input=input_ch_set{2};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spi_data=SPI_data_MSP430_AMS035(sel_input, bias_current, sel_output);
%         ddata=SPI_data_MSP430_AMS035(127,    63,   127);
%                   Sext0-127,B0-5,NEU_S 0-127. 262-bit in total

switch_data=Switch_MSP430_AMS035(RES, SDL, CA, CB, ext_ctrl, active, mode);

command=hex2dec('81');
package=[start_byte_1 start_byte_2 command spi_data switch_data end_byte_1 end_byte_2]';
spi_data=spi_data';
fwrite(uart,package,'uchar');
pause(0.1);

[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package,count] = fread(uart,rtn_package_header(3),'uchar');
spi_data_rtn=rtn_package(35:67);

% clc;
spi_rtn_tmp=zeros(1,8*length(spi_data_rtn));
for i=1:length(spi_data_rtn)
    spi_rtn_tmp((i-1)*8+1:i*8)=bitget(spi_data_rtn(i),[8:-1:1]);
end
if (spi_rtn_tmp(end)==0)&&(spi_rtn_tmp(end-1)==0)
    spi_rtn_tmp2=[0 0 spi_rtn_tmp(1:end-2)];
    spi_rtn_final=((2.^(7:-1:0))*reshape(spi_rtn_tmp2,8,33))';
    
    if isempty(find(spi_rtn_final~=spi_data,1))
        disp('SPI setting correct');
    else
        disp('SPI setting fail');
    end
else
    disp('SPI setting fails');
end
%% Training
DataFile=strcat('decoder_train_AMS035_',Monkey,num2str(N_Moves),'_',num2str(NumberOfNeurons),'_Distri_',num2str(Distri),'_MC.mat');
load(strcat(DataPosition,DataFile));
R_Output_HLN_MC=zeros(length(sel_output),length(R_EventData_MC));
CntEvent=1;
%
for CntEvent=1:length(R_EventData_MC)
%% loading data
disp('Training');
disp('CntEvent=');disp(CntEvent);

Event_tmp=R_EventData_MC{CntEvent,1};
FirstEventTime_high8=floor(Event_tmp(1,1)/256);
FirstEventTime_low8=Event_tmp(1,1)-FirstEventTime_high8*256;
if(FirstEventTime_low8==0)
    FirstEventTime_low8=FirstEventTime_low8+1;
end
FirstEventAddr=Event_tmp(1,2);
Event=zeros(size(Event_tmp,1)-1,size(Event_tmp,2));
Event(:,1)=diff(Event_tmp(:,1));
Event(:,2)=Event_tmp(2:end,2);

command=hex2dec('82');
SampleLength_high8=floor(SampleLength(1,1)/256);
SampleLength_low8=SampleLength(1,1)-SampleLength_high8*256;
Package_LoadData_Srt=uint8([start_byte_1 start_byte_2 command 0 SampleLength_high8 SampleLength_low8...
                            FirstEventTime_high8 FirstEventTime_low8 FirstEventAddr...
                            end_byte_1 end_byte_2]');
EventCount=size(Event_tmp,1);
NumberOfDataFrame=ceil(2*(EventCount-1)/(MAX_PacLen-2));
Package_LoadData=cell(NumberOfDataFrame,1);
for i=1:NumberOfDataFrame
    bg=(i-1)*(MAX_PacLen-2)/2+1;
    stop=min(i*(MAX_PacLen-2)/2,size(Event,1));
    data=reshape((Event(bg:stop,:))',1,2*(stop-bg+1));
    Package_LoadData{i}=uint8([start_byte_1 start_byte_2 command i data end_byte_1 end_byte_2]');
end
Package_LoadData_End=uint8([start_byte_1 start_byte_2 command 255 end_byte_1 end_byte_2]');

LoadStrTime=cputime;
fwrite(uart,Package_LoadData_Srt,'uchar');
%
pause(0.001);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_str,count] = fread(uart,rtn_package_header(3),'uchar');
LoadingCheck=zeros(NumberOfDataFrame+2,1);
if ((rtn_package_str(1)==command)&&(rtn_package_str(2)==0)&&(256*rtn_package_str(4)+rtn_package_str(3)==length(Package_LoadData_Srt)-4))
    LoadingCheck(1)=1;
end
%
rtn_package=zeros(4,NumberOfDataFrame);
for i=1:NumberOfDataFrame
    fwrite(uart,Package_LoadData{i},'uchar');
    pause(0.005);
    [rtn_package_header(1:3),count] = fread(uart,3,'uchar');
    [rtn_package(:,i),count] = fread(uart,rtn_package_header(3),'uchar');
    if ((rtn_package(1,i)==command)&&(rtn_package(2,i)==i)&&(256*rtn_package(4,i)+rtn_package(3,i)==length(Package_LoadData{i})-4))
        LoadingCheck(i+1)=1;
    end
end

fwrite(uart,Package_LoadData_End,'uchar');
pause(0.005);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_end,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_end(1)==command)&&(rtn_package_end(2)==255)&&(256*rtn_package_end(4)+rtn_package_end(3)==2*(EventCount-1)))
    LoadingCheck(end)=1;
end
LoadEndTime=cputime;
LoadingTime=LoadEndTime-LoadStrTime;
if (sum(LoadingCheck)==NumberOfDataFrame+2)
    disp('Data Loading Succeeds!');
else
    disp('Data Loading Fails!');
end
disp(LoadingTime);
%% training
command=hex2dec('83');
NeuronOutputSelection=(2.^(0:7))*reshape(Bin_out,8,16);
Reserved=0;

% parameters loading
ParaLoad=1;
NumberOfOutputNeurons=0;
% TrainMode=2; %1-OM, 2-MC, 3-combined
TrainPackage_ParaLoad=uint8([start_byte_1 start_byte_2 command ParaLoad...
                            Reserved NumberOfOutputNeurons N_ReadOut...
                            NeuronOutputSelection OperationPrd/TimeResolution...
                            TimeSettle/TimeResolution TimeNEU/TimeResolution...
                            TrainMode end_byte_1 end_byte_2]');
% 12: total number of targets
fwrite(uart,TrainPackage_ParaLoad,'uchar');

pause(0.005);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_train_para,count] = fread(uart,rtn_package_header(3),'uchar');
if rtn_package_train_para==1
    disp('Training Parameters Loading is done!');
else
    disp('Training Parameters Loading Fails!');
end
%
% trainig starts
command=hex2dec('83');
ParaLoad=0;
TargetLabel=1;
TrainPackage_Trigger=uint8([start_byte_1 start_byte_2 command ParaLoad TargetLabel...
                            end_byte_1 end_byte_2]');
fwrite(uart,TrainPackage_Trigger,'uchar');
%
pause(0.5);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_train,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_train(1)==N_ReadOut) && (256*rtn_package_train(3)+rtn_package_train(2)==length(sel_output)*N_ReadOut))
    disp('Training is done!');
else
    disp('Training Fails!');
end

%% returing hidden-layer neurons output in trainig
rtn_package_len=2+length(sel_output)*2;
rtn_package_TrainRetrun_tmp=zeros(rtn_package_len,length(sel_ReadOut_2PC));
N_ReadOutReceived=0;
command=hex2dec('86');
while( N_ReadOutReceived<length(sel_ReadOut_2PC))   
    if (N_ReadOutReceived == 0)
        FirstReturn=1;
    else
        FirstReturn=0;
    end
    ReturnPackage=uint8([start_byte_1 start_byte_2 command FirstReturn length(sel_output) end_byte_1 end_byte_2]');
    fwrite(uart,ReturnPackage,'uchar');
    %
    while(uart.BytesAvailable~=rtn_package_len)
    end
    N_ReadOutReceived=N_ReadOutReceived+1;
    disp('N_ReadOutReceived=');
    disp(N_ReadOutReceived);
    [rtn_package_TrainRetrun_tmp(:,N_ReadOutReceived),count] = fread(uart,rtn_package_len,'uchar');
end
pac_tmp=rtn_package_TrainRetrun_tmp(3:end,:);
rtn_package_TrainRetrun=zeros(length(sel_output),length(sel_ReadOut_2PC));
for i=1:length(sel_output)
    rtn_package_TrainRetrun(i,:)=256*pac_tmp(i*2,:)+pac_tmp(i*2-1,:);
end
R_Output_HLN_MC(:,CntEvent)=rtn_package_TrainRetrun;
end

R_TGT_MC=zeros(length(R_Target_MC),1);
for i=1:length(R_Target_MC)
    R_TGT_MC(i)=R_Target_MC{i};
end
save('data_offline_train.mat','R_Output_HLN_MC','R_TGT_MC');

%% off-line Testing
DataFile=strcat('decoder_test_AMS035_',Monkey,num2str(N_Moves),'_',num2str(NumberOfNeurons),'_Distri_',num2str(Distri),'_MC.mat');
load(strcat(DataPosition,DataFile));
T_Output_HLN_MC=zeros(length(sel_output),length(T_EventData_MC));
CntEvent=1;
%
for CntEvent=1:length(T_EventData_MC)
%% loading off-line testing data
disp('Training');
disp('CntEvent=');disp(CntEvent);

Event_tmp=T_EventData_MC{CntEvent,1};
FirstEventTime_high8=floor(Event_tmp(1,1)/256);
FirstEventTime_low8=Event_tmp(1,1)-FirstEventTime_high8*256;
if(FirstEventTime_low8==0)
    FirstEventTime_low8=FirstEventTime_low8+1;
end
FirstEventAddr=Event_tmp(1,2);
Event=zeros(size(Event_tmp,1)-1,size(Event_tmp,2));
Event(:,1)=diff(Event_tmp(:,1));
Event(:,2)=Event_tmp(2:end,2);

command=hex2dec('82');
SampleLength_high8=floor(SampleLength(1,1)/256);
SampleLength_low8=SampleLength(1,1)-SampleLength_high8*256;
Package_LoadData_Srt=uint8([start_byte_1 start_byte_2 command 0 SampleLength_high8 SampleLength_low8...
                            FirstEventTime_high8 FirstEventTime_low8 FirstEventAddr...
                            end_byte_1 end_byte_2]');
EventCount=size(Event_tmp,1);
NumberOfDataFrame=ceil(2*(EventCount-1)/(MAX_PacLen-2));
Package_LoadData=cell(NumberOfDataFrame,1);
for i=1:NumberOfDataFrame
    bg=(i-1)*(MAX_PacLen-2)/2+1;
    stop=min(i*(MAX_PacLen-2)/2,size(Event,1));
    data=reshape((Event(bg:stop,:))',1,2*(stop-bg+1));
    Package_LoadData{i}=uint8([start_byte_1 start_byte_2 command i data end_byte_1 end_byte_2]');
end
Package_LoadData_End=uint8([start_byte_1 start_byte_2 command 255 end_byte_1 end_byte_2]');

LoadStrTime=cputime;
fwrite(uart,Package_LoadData_Srt,'uchar');
%
% pause(0.001);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_str,count] = fread(uart,rtn_package_header(3),'uchar');
LoadingCheck=zeros(NumberOfDataFrame+2,1);
if ((rtn_package_str(1)==command)&&(rtn_package_str(2)==0)&&(256*rtn_package_str(4)+rtn_package_str(3)==length(Package_LoadData_Srt)-4))
    LoadingCheck(1)=1;
end
%
rtn_package=zeros(4,NumberOfDataFrame);
for i=1:NumberOfDataFrame
    fwrite(uart,Package_LoadData{i},'uchar');
%     pause(0.005);
    [rtn_package_header(1:3),count] = fread(uart,3,'uchar');
    [rtn_package(:,i),count] = fread(uart,rtn_package_header(3),'uchar');
    if ((rtn_package(1,i)==command)&&(rtn_package(2,i)==i)&&(256*rtn_package(4,i)+rtn_package(3,i)==length(Package_LoadData{i})-4))
        LoadingCheck(i+1)=1;
    end
end

fwrite(uart,Package_LoadData_End,'uchar');
% pause(0.001);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_end,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_end(1)==command)&&(rtn_package_end(2)==255)&&(256*rtn_package_end(4)+rtn_package_end(3)==2*(EventCount-1)))
    LoadingCheck(end)=1;
end
LoadEndTime=cputime;
LoadingTime=LoadEndTime-LoadStrTime;
if (sum(LoadingCheck)==NumberOfDataFrame+2)
    disp('Data Loading Succeeds!');
else
    disp('Data Loading Fails!');
end
disp(LoadingTime);
%% testing (off-line)
command=hex2dec('83');
NeuronOutputSelection=(2.^(0:7))*reshape(Bin_out,8,16);
Reserved=0;

% parameters loading
ParaLoad=1;
NumberOfOutputNeurons=0;
% TrainMode=2; %1-OM, 2-MC, 3-combined
TrainPackage_ParaLoad=uint8([start_byte_1 start_byte_2 command ParaLoad...
                            Reserved NumberOfOutputNeurons N_ReadOut...
                            NeuronOutputSelection OperationPrd/TimeResolution...
                            TimeSettle/TimeResolution TimeNEU/TimeResolution...
                            TrainMode end_byte_1 end_byte_2]');
% 12: total number of targets
fwrite(uart,TrainPackage_ParaLoad,'uchar');

%
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_train_para,count] = fread(uart,rtn_package_header(3),'uchar');
if rtn_package_train_para==1
    disp('Training Parameters Loading is done!');
else
    disp('Training Parameters Loading Fails!');
end
%
% trainig starts
command=hex2dec('83');
ParaLoad=0;
TargetLabel=1;
TrainPackage_Trigger=uint8([start_byte_1 start_byte_2 command ParaLoad TargetLabel...
                            end_byte_1 end_byte_2]');
fwrite(uart,TrainPackage_Trigger,'uchar');
%
pause(0.5);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_train,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_train(1)==N_ReadOut) && (256*rtn_package_train(3)+rtn_package_train(2)==length(sel_output)*N_ReadOut))
    disp('Training is done!');
else
    disp('Training Fails!');
end

%% returing hidden-layer neurons output in testing (off-line)
rtn_package_len=2+length(sel_output)*2;
rtn_package_TrainRetrun_tmp=zeros(rtn_package_len,length(sel_ReadOut_2PC));
N_ReadOutReceived=0;
command=hex2dec('86');
while( N_ReadOutReceived<length(sel_ReadOut_2PC))   
    if (N_ReadOutReceived == 0)
        FirstReturn=1;
    else
        FirstReturn=0;
    end
    ReturnPackage=uint8([start_byte_1 start_byte_2 command FirstReturn length(sel_output) end_byte_1 end_byte_2]');
    N_ReadOutReceived=N_ReadOutReceived+1;
    fwrite(uart,ReturnPackage,'uchar');
    while(uart.BytesAvailable~=rtn_package_len)
    end
    [rtn_package_TrainRetrun_tmp(:,N_ReadOutReceived),count] = fread(uart,rtn_package_len,'uchar');
    disp('N_ReadOutReceived=');
    disp(N_ReadOutReceived);
end
pac_tmp=rtn_package_TrainRetrun_tmp(3:end,:);
rtn_package_TrainRetrun=zeros(length(sel_output),length(sel_ReadOut_2PC));
for i=1:length(sel_output)
    rtn_package_TrainRetrun(i,:)=256*pac_tmp(i*2,:)+pac_tmp(i*2-1,:);
end
T_Output_HLN_MC(:,CntEvent)=rtn_package_TrainRetrun;
end

T_TGT_MC=zeros(length(T_Target_MC),1);
for i=1:length(T_Target_MC)
    T_TGT_MC(i)=T_Target_MC{i};
end
save('data_offline_test.mat','T_Output_HLN_MC','T_TGT_MC');

%% off-line modeling
Elm_type=1;
WightMethod=0;
NOB_CNT=[7:12];
c_power=[-16:4:16];
RA_NOB=zeros(length(NOB_CNT),1);
TA_NOB=zeros(length(NOB_CNT),1);
CPmax_NOB=zeros(length(NOB_CNT),1);
for i=1:length(NOB_CNT)
    Cmax=2^NOB_CNT(i)-1;
    TA_NOB(i)=0;
    for j=1:length(c_power)
        [TrainingTime,TrainingAccuracy] = elm_train_cy_chip_AMS035(R_Output_HLN_MC, R_TGT_MC', NumberOfNeurons, Elm_type, WightMethod,c_power(j),Cmax);
        [TestingTime,TestingAccuracy] = elm_predict_cy_chip_AMS035(T_Output_HLN_MC, T_TGT_MC', Cmax);
        if TA_NOB(i)<TestingAccuracy
            TA_NOB(i)=TestingAccuracy;
            RA_NOB(i)=TrainingAccuracy;
            CPmax_NOB(i)=c_power(j);
        end            
    end
end

figure;
plot(NOB_CNT,RA_NOB);hold on;
plot(NOB_CNT,TA_NOB,'r');
figure;
plot(NOB_CNT,CPmax_NOB);

NOB_CNT_max=NOB_CNT(TA_NOB==max(TA_NOB));
if length(NOB_CNT_max)>1
    NOB_CNT_max=NOB_CNT_max(1);
end
Cpower_MAX=CPmax_NOB(NOB_CNT==NOB_CNT_max);
% run again at best performace
[TrainingTime,TrainingAccuracy] = elm_train_cy_chip_AMS035(R_Output_HLN_MC, R_TGT_MC', NumberOfNeurons, Elm_type, WightMethod,Cpower_MAX,2^NOB_CNT_max-1);
[TestingTime,TestingAccuracy] = elm_predict_cy_chip_AMS035(T_Output_HLN_MC, T_TGT_MC', 2^NOB_CNT_max-1);
%% load output weights
command=hex2dec('84');

%%%%%%%%%%%%%% MC weights processing and saving %%%%%%%%%%%%
% pre-process output weight: turn into signed 16 bit
File_OutputWeights=strcat(SavePosition,'elm_model_AMS035_MC.mat');
load(File_OutputWeights);
OutputWeights_MC=OutputWeight;
NOB_Weight=16;
beta=2;
pos_max=max(max(abs(OutputWeights_MC)))*beta;
RES_OutputWeight_MC=pos_max/(2^(NOB_Weight-1)-1);
OutputWeights_MC=round(OutputWeights_MC/RES_OutputWeight_MC);
OutputWeights_MC_org=OutputWeights_MC';
ind_neg=find(OutputWeights_MC<0);
OutputWeights_MC(ind_neg)=OutputWeights_MC(ind_neg)+2^NOB_Weight;
save(strcat(SavePosition,'OutputWeight_MC_16bit_signed.mat'),'OutputWeights_MC','RES_OutputWeight_MC','OutputWeights_MC_org','NOB_Weight');
%%%%%%%%%%%%%% MC weights processing and saving %%%%%%%%%%%%

% % % MC weights
% % load(strcat(SavePosition,'OutputWeight_MC_16bit_signed.mat'));


%%%%%%%%%%%%%% OM weights processing and saving %%%%%%%%%%%%
% pre-process output weight: turn into signed 16 bit
File_OutputWeights=strcat(SavePosition,'elm_model_AMS035_OM.mat');
load(File_OutputWeights);
OutputWeights_OM=OutputWeight;
NOB_Weight=16;
beta=2;
pos_max=max(max(abs(OutputWeights_OM)))*beta;
RES_OutputWeight_OM=pos_max/(2^(NOB_Weight-1)-1);
OutputWeights_OM=round(OutputWeights_OM/RES_OutputWeight_OM);
OutputWeights_OM_org=OutputWeights_OM';
ind_neg=find(OutputWeights_OM<0);
OutputWeights_OM(ind_neg)=OutputWeights_OM(ind_neg)+2^NOB_Weight;
save(strcat(SavePosition,'OutputWeight_OM_16bit_signed.mat'),'OutputWeights_OM','RES_OutputWeight_OM','OutputWeights_OM_org','NOB_Weight');
%%%%%%%%%%%%%% OM weights processing and saving %%%%%%%%%%%%

% % % OM weights
% % load(strcat(SavePosition,'OutputWeight_OM_16bit_signed.mat'));

%%
% load OM weights into MSP430; OM always goes first
LoadingWeightsType=0;   % 0 for loading OM weights; 1 for loading MC weights; OM always goes firstly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OutputWeights=OutputWeights_OM;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NumberOfOutputNeurons=size(OutputWeights,2);
NumberOfWeights=length(sel_output)*NumberOfOutputNeurons;
NumberOfBytesInWeights=NumberOfWeights*NOB_Weight/8;

OutputWeights=reshape(OutputWeights,1,NumberOfWeights);
WeightsInByte=zeros(1,NumberOfBytesInWeights);
for i=1:length(OutputWeights)
    WeightsInByte(i*2)=floor(OutputWeights(i)/256);
    WeightsInByte(i*2-1)=OutputWeights(i)-WeightsInByte(i*2)*256;
end

Package_LoadWeights_Srt=uint8([start_byte_1 start_byte_2 command 0 NumberOfOutputNeurons LoadingWeightsType end_byte_1 end_byte_2]');
NumberOfDataFrame=ceil(NumberOfBytesInWeights/(MAX_PacLen-2));
Package_LoadWeights=cell(NumberOfDataFrame,1);
for i=1:NumberOfDataFrame
    data=WeightsInByte((i-1)*(MAX_PacLen-2)+1:min(i*(MAX_PacLen-2),NumberOfBytesInWeights));
    Package_LoadWeights{i}=uint8([start_byte_1 start_byte_2 command i data end_byte_1 end_byte_2]');
end
Package_LoadWeights_End=uint8([start_byte_1 start_byte_2 command 255 end_byte_1 end_byte_2]');

LoadStrTime=cputime;
fwrite(uart,Package_LoadWeights_Srt,'uchar');

pause(0.001);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_str,count] = fread(uart,rtn_package_header(3),'uchar');
LoadingCheck=zeros(NumberOfDataFrame+2,1);
if ((rtn_package_str(1)==command)&&(rtn_package_str(2)==0)&&(256*rtn_package_str(4)+rtn_package_str(3)==length(Package_LoadWeights_Srt)-4))
    LoadingCheck(1)=1;
end
%
rtn_package=zeros(4,NumberOfDataFrame);
for i=1:NumberOfDataFrame
    fwrite(uart,Package_LoadWeights{i},'uchar');
    pause(0.005);
    [rtn_package_header(1:3),count] = fread(uart,3,'uchar');
    [rtn_package(:,i),count] = fread(uart,rtn_package_header(3),'uchar');
    if ((rtn_package(1,i)==command)&&(rtn_package(2,i)==i)&&(256*rtn_package(4,i)+rtn_package(3,i)==length(Package_LoadWeights{i})-4))
        LoadingCheck(i+1)=1;
    end
end

fwrite(uart,Package_LoadWeights_End,'uchar');
pause(0.005);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_end,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_end(1)==command)&&(rtn_package_end(2)==255)&&(256*rtn_package_end(4)+rtn_package_end(3)==NumberOfBytesInWeights))
    LoadingCheck(end)=1;
end
LoadEndTime=cputime;
LoadingTime=LoadEndTime-LoadStrTime;
if (sum(LoadingCheck)==NumberOfDataFrame+2)
    disp('Data Loading Succeeds!');
else
    disp('Data Loading Fails!');
end
disp(LoadingTime);

%
% load MC weights into MSP; OM always goes first
LoadingWeightsType=1;   % 0 for loading OM weights; 1 for loading MC weights; OM always goes firstly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OutputWeights=OutputWeights_MC;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NumberOfOutputNeurons=size(OutputWeights,2);
NumberOfWeights=length(sel_output)*NumberOfOutputNeurons;
NumberOfBytesInWeights=NumberOfWeights*NOB_Weight/8;

OutputWeights=reshape(OutputWeights,1,NumberOfWeights);
WeightsInByte=zeros(1,NumberOfBytesInWeights);
for i=1:length(OutputWeights)
    WeightsInByte(i*2)=floor(OutputWeights(i)/256);
    WeightsInByte(i*2-1)=OutputWeights(i)-WeightsInByte(i*2)*256;
end

Package_LoadWeights_Srt=uint8([start_byte_1 start_byte_2 command 0 NumberOfOutputNeurons LoadingWeightsType end_byte_1 end_byte_2]');
NumberOfDataFrame=ceil(NumberOfBytesInWeights/(MAX_PacLen-2));
Package_LoadWeights=cell(NumberOfDataFrame,1);
for i=1:NumberOfDataFrame
    data=WeightsInByte((i-1)*(MAX_PacLen-2)+1:min(i*(MAX_PacLen-2),NumberOfBytesInWeights));
    Package_LoadWeights{i}=uint8([start_byte_1 start_byte_2 command i data end_byte_1 end_byte_2]');
end
Package_LoadWeights_End=uint8([start_byte_1 start_byte_2 command 255 end_byte_1 end_byte_2]');

LoadStrTime=cputime;
fwrite(uart,Package_LoadWeights_Srt,'uchar');

pause(0.001);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_str,count] = fread(uart,rtn_package_header(3),'uchar');
LoadingCheck=zeros(NumberOfDataFrame+2,1);
if ((rtn_package_str(1)==command)&&(rtn_package_str(2)==0)&&(256*rtn_package_str(4)+rtn_package_str(3)==length(Package_LoadWeights_Srt)-4))
    LoadingCheck(1)=1;
end
%
rtn_package=zeros(4,NumberOfDataFrame);
for i=1:NumberOfDataFrame
    fwrite(uart,Package_LoadWeights{i},'uchar');
    pause(0.01);
    [rtn_package_header(1:3),count] = fread(uart,3,'uchar');
    [rtn_package(:,i),count] = fread(uart,rtn_package_header(3),'uchar');
    if ((rtn_package(1,i)==command)&&(rtn_package(2,i)==i)&&(256*rtn_package(4,i)+rtn_package(3,i)==length(Package_LoadWeights{i})-4))
        LoadingCheck(i+1)=1;
    end
end

fwrite(uart,Package_LoadWeights_End,'uchar');
pause(0.005);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_end,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_end(1)==command)&&(rtn_package_end(2)==255)&&(256*rtn_package_end(4)+rtn_package_end(3)==NumberOfBytesInWeights))
    LoadingCheck(end)=1;
end
LoadEndTime=cputime;
LoadingTime=LoadEndTime-LoadStrTime;
if (sum(LoadingCheck)==NumberOfDataFrame+2)
    disp('Data Loading Succeeds!');
else
    disp('Data Loading Fails!');
end
disp(LoadingTime);
%% on-line testing
DataFile=strcat('decoder_test_AMS035_',Monkey,num2str(N_Moves),'_',num2str(NumberOfNeurons),'_Distri_',num2str(Distri),'_OM.mat');
load(strcat(DataPosition,DataFile));
T_TGT_OM=zeros(length(T_Target_OM)*length(sel_ReadOut_2PC),1);
for i=1:length(T_Target_OM)
    T_TGT_OM((i-1)*length(sel_ReadOut_2PC)+1:i*length(sel_ReadOut_2PC))=T_Target_OM{i};
end
FinalOutput_OM=zeros(length(T_Target_OM)*length(sel_ReadOut_2PC),1);
T_Output_ON_OM=zeros(1,length(T_Target_OM)*length(sel_ReadOut_2PC));
CntEvent=7;
%
for CntEvent=1:length(T_EventData_OM)
%% loading data
disp('On-line Testing');
disp('CntEvent=');disp(CntEvent);

Event_tmp=T_EventData_OM{CntEvent,1};
FirstEventTime_high8=floor(Event_tmp(1,1)/256);
FirstEventTime_low8=Event_tmp(1,1)-FirstEventTime_high8*256;
if(FirstEventTime_low8==0)
    FirstEventTime_low8=FirstEventTime_low8+1;
end
FirstEventAddr=Event_tmp(1,2);
Event=zeros(size(Event_tmp,1)-1,size(Event_tmp,2));
Event(:,1)=diff(Event_tmp(:,1));
Event(:,2)=Event_tmp(2:end,2);

command=hex2dec('82');
SampleLength_high8=floor(SampleLength(1,1)/256);
SampleLength_low8=SampleLength(1,1)-SampleLength_high8*256;
Package_LoadData_Srt=uint8([start_byte_1 start_byte_2 command 0 SampleLength_high8 SampleLength_low8...
                            FirstEventTime_high8 FirstEventTime_low8 FirstEventAddr...
                            end_byte_1 end_byte_2]');
EventCount=size(Event_tmp,1);
NumberOfDataFrame=ceil(2*(EventCount-1)/(MAX_PacLen-2));
Package_LoadData=cell(NumberOfDataFrame,1);
for i=1:NumberOfDataFrame
    bg=(i-1)*(MAX_PacLen-2)/2+1;
    stop=min(i*(MAX_PacLen-2)/2,size(Event,1));
    data=reshape((Event(bg:stop,:))',1,2*(stop-bg+1));
    Package_LoadData{i}=uint8([start_byte_1 start_byte_2 command i data end_byte_1 end_byte_2]');
end
Package_LoadData_End=uint8([start_byte_1 start_byte_2 command 255 end_byte_1 end_byte_2]');

LoadStrTime=cputime;
fwrite(uart,Package_LoadData_Srt,'uchar');
%
pause(0.001);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_str,count] = fread(uart,rtn_package_header(3),'uchar');
LoadingCheck=zeros(NumberOfDataFrame+2,1);
if ((rtn_package_str(1)==command)&&(rtn_package_str(2)==0)&&(256*rtn_package_str(4)+rtn_package_str(3)==length(Package_LoadData_Srt)-4))
    LoadingCheck(1)=1;
end
%
rtn_package=zeros(4,NumberOfDataFrame);
for i=1:NumberOfDataFrame
    fwrite(uart,Package_LoadData{i},'uchar');
    pause(0.005);
    [rtn_package_header(1:3),count] = fread(uart,3,'uchar');
    [rtn_package(:,i),count] = fread(uart,rtn_package_header(3),'uchar');
    if ((rtn_package(1,i)==command)&&(rtn_package(2,i)==i)&&(256*rtn_package(4,i)+rtn_package(3,i)==length(Package_LoadData{i})-4))
        LoadingCheck(i+1)=1;
    end
end

fwrite(uart,Package_LoadData_End,'uchar');
pause(0.005);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_end,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_end(1)==command)&&(rtn_package_end(2)==255)&&(256*rtn_package_end(4)+rtn_package_end(3)==2*(EventCount-1)))
    LoadingCheck(end)=1;
end
LoadEndTime=cputime;
LoadingTime=LoadEndTime-LoadStrTime;
if (sum(LoadingCheck)==NumberOfDataFrame+2)
    disp('Data Loading Succeeds!');
else
    disp('Data Loading Fails!');
end
disp(LoadingTime);

%% testing
command=hex2dec('85');
NeuronOutputSelection=(2.^(0:7))*reshape(Bin_out,8,16);
OperationPrd=20e-3;
TimeNEU=10e-3;
TimeSettle=5e-3;
TimeResolution=0.2e-3;
Reserved=0;
N_ReadOut=101;
% parameters loading
ParaLoad=2;
NumberOfOutputNeurons=1;
DecodeMode=3; % 0-random projection, 1-OM, 2-MC, 3-combined
Thr_OM=0.6;
Thr_OM=round(Thr_OM/RES_OutputWeight_OM);

Thr_OM_Byte3=floor(Thr_OM/16777216);
Thr_OM_Byte2=floor(mod(Thr_OM,16777216)/65536);
Thr_OM_Byte1=floor(mod(Thr_OM,65536)/256);
Thr_OM_Byte0=mod(Thr_OM,256);
Thr_OM_4Bytes=[Thr_OM_Byte0 Thr_OM_Byte1 Thr_OM_Byte2 Thr_OM_Byte3];

hyster_prd=10;
pos_cnt=5;
OMPrd=10;
RefraPrd=16;


TestPackage_ParaLoad=uint8([start_byte_1 start_byte_2 command ParaLoad DecodeMode ...
                            NumberOfOutputNeurons N_ReadOut NeuronOutputSelection ...
                            OperationPrd/TimeResolution TimeSettle/TimeResolution ...
                            TimeNEU/TimeResolution Thr_OM_4Bytes hyster_prd pos_cnt...
                            OMPrd RefraPrd end_byte_1 end_byte_2]');
% 12: total number of targets
fwrite(uart,TestPackage_ParaLoad,'uchar');
%
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_test_para,count] = fread(uart,rtn_package_header(3),'uchar');
if rtn_package_test_para==1
    disp('Testing Parameters Loading is done!');
else
    disp('Testing Parameters Loading Fails!');
end
%
% testing starts
command=hex2dec('85');
ParaLoad=0;
TargetLabel=1;
pause(0.05);

TestPackage_Trigger=uint8([start_byte_1 start_byte_2 command ParaLoad TargetLabel end_byte_1 end_byte_2]');
fwrite(uart,TestPackage_Trigger,'uchar');

% % while( uart.BytesAvailable<N_ReadOut )   
% % end
% % [rtn_package_finaloutput,count] = fread(uart,N_ReadOut,'uchar');
N_FinalOuput=1;
while(N_FinalOuput <= N_ReadOut)
    while( uart.BytesAvailable<1 )   
    end
    [rtn_package_finaloutput(N_FinalOuput),count] = fread(uart,1,'uchar');
    rtn_package_finaloutput(N_FinalOuput)
    N_FinalOuput=N_FinalOuput+1;
end
    
pause(0.05);
[rtn_package_header(1:3),count] = fread(uart,3,'uchar');
[rtn_package_test,count] = fread(uart,rtn_package_header(3),'uchar');
if ((rtn_package_test(1)==N_ReadOut) && (256*rtn_package_test(3)+rtn_package_test(2)==N_ReadOut*NumberOfOutputNeurons))
    disp('Testing is done!');
else
    disp('Testing Fails!');
end
FinalOutput_OM((CntEvent-1)*length(sel_ReadOut_2PC)+1:CntEvent*length(sel_ReadOut_2PC))=rtn_package_finaloutput(sel_ReadOut_2PC);

%% returing output stage neurons output in testing (on-line)
rtn_package_len=2+NumberOfOutputNeurons*4;
rtn_package_TestRetrun_tmp=zeros(rtn_package_len,N_ReadOut);
N_ReadOutReceived=0;
command=hex2dec('88');
while( N_ReadOutReceived<N_ReadOut )   
    if (N_ReadOutReceived == 0)
        FirstReturn=1;
    else
        FirstReturn=0;
    end
    ReturnPackage=uint8([start_byte_1 start_byte_2 command FirstReturn NumberOfOutputNeurons*2 end_byte_1 end_byte_2]');
    N_ReadOutReceived=N_ReadOutReceived+1;
    fwrite(uart,ReturnPackage,'uchar');
    while(uart.BytesAvailable~=rtn_package_len)
    end
    [rtn_package_TestRetrun_tmp(:,N_ReadOutReceived),count] = fread(uart,rtn_package_len,'uchar');
    disp('N_ReadOutReceived=');
    disp(N_ReadOutReceived);
end
pac_tmp=rtn_package_TestRetrun_tmp(3:end,:);
rtn_package_TestRetrun=zeros(NumberOfOutputNeurons,N_ReadOut);
for i=1:NumberOfOutputNeurons
    rtn_package_TestRetrun(i,:)=16777216*pac_tmp(i*4,:)+65536*pac_tmp(i*4-1,:)+256*pac_tmp(i*4-2,:)+pac_tmp(i*4-3,:);
end
T_Output_ON_OM(:,(CntEvent-1)*length(sel_ReadOut_2PC)+1:CntEvent*length(sel_ReadOut_2PC))=rtn_package_TestRetrun(:,sel_ReadOut_2PC);
end

ind_neg_res=find(T_Output_ON_OM>(2^31-1));
Output_elm=T_Output_ON_OM;
Output_elm(ind_neg_res)=Output_elm(ind_neg_res)-2^32;
Output_elm=Output_elm*RES_OutputWeight_OM;

figure;
plot(T_TGT_OM);hold on;
plot(FinalOutput_OM,'r');
plot(Output_elm,'k');
%% returning output neuron value output in testing
rtn_package_len=2+NumberOfOutputNeurons*4;
rtn_package_TestRetrun_tmp=zeros(rtn_package_len,N_ReadOut);
N_ReadOutReceived=0;
command=hex2dec('88');
while( N_ReadOutReceived<N_ReadOut )   
    if (N_ReadOutReceived == 0)
        FirstReturn=1;
    else
        FirstReturn=0;
    end
    ReturnPackage=uint8([start_byte_1 start_byte_2 command FirstReturn NumberOfOutputNeurons*2 end_byte_1 end_byte_2]');
    N_ReadOutReceived=N_ReadOutReceived+1;
    fwrite(uart,ReturnPackage,'uchar');
    while(uart.BytesAvailable~=rtn_package_len)
    end
    [rtn_package_TestRetrun_tmp(:,N_ReadOutReceived),count] = fread(uart,rtn_package_len,'uchar');
    disp('N_ReadOutReceived=');
    disp(N_ReadOutReceived);
end
pac_tmp=rtn_package_TestRetrun_tmp(3:end,:);
rtn_package_TestRetrun=zeros(NumberOfOutputNeurons,N_ReadOut);
for i=1:NumberOfOutputNeurons
    rtn_package_TestRetrun(i,:)=16777216*pac_tmp(i*4,:)+65536*pac_tmp(i*4-1,:)+256*pac_tmp(i*4-2,:)+pac_tmp(i*4-3,:);
end
ind_neg_res=find(rtn_package_TestRetrun>(2^31-1));
Output_elm=rtn_package_TestRetrun;
Output_elm(ind_neg_res)=Output_elm(ind_neg_res)-2^32;
Output_elm=Output_elm*d;
figure;
plot(Output_elm');

%%
fclose(uart);