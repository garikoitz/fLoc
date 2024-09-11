addpath(genpath('/Applications/Psychtoolbox'))
wdir='/Users/experimentaluser/THALENT_test/real_exp_THALENT_2023';

% Scan the HID device 'Current Designs, Inc.'
% fill your devices with the manufacturer's name
manufacturerResponseBox='Current Designs, Inc.';
manufacturerAppleKeyboard='Apple, Inc';
manufacturerTrigger='Code Mercenaries';

devices=PsychHID('Devices');
KeyboardIndices=GetKeyboardIndices();

deviceIDCurdes=KeyboardIndices(strcmp({devices(KeyboardIndices).manufacturer}, ...
    manufacturerResponseBox)==1);
deviceIDApple=KeyboardIndices(strcmp({devices(KeyboardIndices).manufacturer}, ...
    manufacturerAppleKeyboard)==1);
deviceIDTrigger=KeyboardIndices(strcmp({devices(KeyboardIndices).manufacturer}, ...
    manufacturerTrigger)==1);

% check the keyCodes of the device and store them
keyCodes = [30, 31, 32, 33];
keyNames = {'right' 'right' 'left' 'left'}; % give to the keyCodes a
                                            % response name
keyTrigger = 22;
%% Edit this variables to run the desired block
% sub001 --> package1
subID='Tiger';
paradigm='contextual_cueing_paradigm';
package=3;
runint=6;
% create the folder to save logs
paradigm_folder = fullfile('/Users/experimentaluser/THALENT_test',subID,paradigm);
if ~exist(paradigm_folder,'dir')
    mkdir(paradigm_folder)
end

%% Read the .csv content of the specific run
run=strcat('run',int2str(runint));
% Get a list of all csv files in the selected packacge
pckdir=fullfile(wdir,strcat('package_',int2str(package)),paradigm);
filePattern=fullfile(pckdir,'*.csv');
theFiles = dir(filePattern);
for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    if contains(baseFileName,run)
        fullFileName = fullfile(theFiles(k).folder, baseFileName);
        fprintf(1, 'Now reading %s\n', fullFileName);
        % Here read the content
        content=readcell(fullFileName);
        fprintf(1, 'Finish reading %s\n', fullFileName);
    end
end
fixation='fixationDot.png';
% images dir to display. The name of the first column of the content is que
% folder directory
imgdir=fullfile(pckdir,content{1,1},'images');
images=content(2:end,1);
cresponses=content(2:end,2);
imgList=fullfile(imgdir,images);
fixation=fullfile(fullfile(wdir,'common'),fixation);

% get the times by optseq in case of contextual or goal oriented paradigms
if strcmp(paradigm,'contextual_cueing_paradigm') || strcmp(paradigm,'goal_oriented_paradigm')
    duration=content(2:end,strcmp(content(1,:),'duration'));
    % get refined duration times for optimal frame presentation given the fresh
    %  rate of the monitor
    fhz=60; % 85Hz is also possible
    durationRefined=zeros(length(duration),1);

    for dr=1:length(duration)
        % stimulidurationCheck processes time in ms, that's why *1000 and then
        % I pass the time to the original units, i.e., secs.
        durationRefined(dr)=stimulidurationCheck(fhz,duration{dr}*1000) / 1000;
    end
end

if strcmp(paradigm,'goal_oriented_paradigm')
    cueList=content(2:end,strcmp(content(1,:),'cue'));
    cues=fullfile(fullfile(wdir,'common'),...
    {'Q1_cue.png';'Q2_cue.png';'Q3_cue.png';'Q4_cue.png'});
    [appearance,appearanceCue,appearanceAfterFixation,appearanceJitter,...
        RT,responses]=THALENT_ORIENTED(imgList,cueList,durationRefined,...
        fixation,cues,deviceIDTrigger,deviceIDCurdes,keyTrigger,keyCodes,keyNames);
elseif strcmp(paradigm,'contextual_cueing_paradigm')
    [appearance,appearanceFixation,...
        appearanceAfterFixation,appearanceJitter,...
        RT,responses]=THALENT_CONTEXTUAL(imgList,durationRefined,fixation,...
        deviceIDTrigger,deviceIDCurdes,keyTrigger,keyCodes,keyNames);
end

%% save the log file
idxStim=~contains(imgList,'fixation');
responses2=responses(idxStim);
cresponses2=cresponses(idxStim);

z=0;
ncorrect=0;
accuracy=zeros(length(responses2),1);
for i=1:length(responses2)
    if isempty(responses2{i,1})
        responses2{i,1} = ' ';
    end
    z=z+1;
    if strcmp(responses2{i,1},cresponses2{i,1})
        ncorrect=ncorrect+1;
    end
    accuracy(i)=(ncorrect/z)*100;
end


% second version to see jitter onsets, just in case
z=0;
ncorrect=0;
accuracy2=zeros(length(responses),1);
for i=1:length(responses)
    if strcmp(images{i},'fixationDot.png')
        continue;
    else
        if isempty(responses{i,1})
        responses{i,1} = ' ';
        end
        z=z+1;
        if strcmp(responses{i,1},cresponses{i,1})
            ncorrect=ncorrect+1;
        end
        accuracy2(i)=(ncorrect/z)*100;
    end
end


if strcmp(paradigm, 'goal_oriented_paradigm')
    % compute the general accuracy
    varNames={'image','appearance cue (ms)','appearance (ms)',...
        'response time (ms)','response','correct response',...
        'general accuracy (%)'};
    varNames2=[varNames,'jitter appearance (ms)'];

    logdata=table(images(idxStim),appearanceCue(idxStim),...
        appearance(idxStim),RT(idxStim),responses2,cresponses2,...
        accuracy,'VariableNames', varNames);
    
    logdata2=table(images,appearanceCue,...
        appearance,RT,responses,cresponses,...
        accuracy2,appearanceJitter,'VariableNames', varNames2);
else
    % compute the general accuracy
    varNames={'image','appearance fixation (ms)','appearance (ms)',...
        'response time (ms)','response','correct response',...
        'general accuracy (%)'};
    varNames2=[varNames,'jitter appearance (ms)'];

    logdata=table(images(idxStim),appearanceFixation(idxStim),...
        appearance(idxStim),RT(idxStim),responses2,cresponses2,...
        accuracy,'VariableNames', varNames);
    
    logdata2=table(images,appearanceFixation,...4
        appearance,RT,responses,cresponses,...
        accuracy2,appearanceJitter,'VariableNames', varNames2);
end

% writetable(logdata,fullfile(pckdir,content{1,1},strcat('sub-',subID,'_',strcat('run-00',int2str(runint)),'.csv')));
% writetable(logdata2,fullfile(pckdir,content{1,1},strcat('sub-',subID,'_',strcat('run-00',int2str(runint)),'_V2.csv')));

writetable(logdata,fullfile(paradigm_folder,strcat('sub-',subID,'_',strcat('run-0',int2str(runint)),'.csv')));
writetable(logdata2,fullfile(paradigm_folder,strcat('sub-',subID,'_',strcat('run-0',int2str(runint)),'_V2.csv')));

%% Now run the eccentricity experiment
[appearance,appearanceFixation,RT,responses]=THALENT_ECC_TEST_V2(imgList,fixation,...
    deviceIDCurdes,keyCodes,keyNames);

%% Now run the CONTEXTUAL experiment
[appearance,appearanceFixation,...
    appearanceAfterFixation,appearanceJitter,...
    RT,responses]=THALENT_CONTEXTUAL(imgList,durationRefined,fixation,...
    deviceIDTrigger,deviceIDCurdes,keyTrigger,keyCodes,keyNames);

% idxStim=~contains(imgList,'fixation');
% % idxStim=find(idxStim == 1);
% responses=responses(idxStim);
% cresponses=cresponses(idxStim);
% 
% z=0;
% ncorrect=0;
% accuracy=zeros(length(responses),1);
% for i=1:length(responses)
%     if isempty(responses{i,1})
%         responses{i,1} = ' ';
%     end
%     z=z+1;
%     if strcmp(responses{i,1},cresponses{i,1})
%         ncorrect=ncorrect+1;
%     end
%     accuracy(i)=(ncorrect/z)*100;
% end
% 
% % compute the general accuracy
% varNames={'image','appearance fixation (ms)','appearance (ms)',...
%     'response time (ms)','response','correct response',...
%     'general accuracy (%)'};
% 
% logdata=table(images(idxStim),appearanceFixation(idxStim),...
%     appearance(idxStim),RT(idxStim),responses,cresponses,...
%     accuracy,'VariableNames', varNames);
% 
% writetable(logdata,fullfile(pckdir,content{1,1},strcat(subID,'_',run,'.csv')));
%% Now run the ORIENTED experiment
cues=fullfile(fullfile(wdir,'common'),...
    {'Q1_cue.png';'Q2_cue.png';'Q3_cue.png';'Q4_cue.png'});

[appearance,appearanceCue,appearanceAfterFixation,appearanceJitter,...
    RT,responses]=THALENT_ORIENTED(imgList,cueList,durationRefined,...
    fixation,cues,deviceIDTrigger,deviceIDCurdes,keyTrigger,keyCodes,keyNames);

%% save the log file
idxStim=~contains(imgList,'fixation');
responses2=responses(idxStim);
cresponses2=cresponses(idxStim);

z=0;
ncorrect=0;
accuracy=zeros(length(responses2),1);
for i=1:length(responses2)
    if isempty(responses2{i,1})
        responses2{i,1} = ' ';
    end
    z=z+1;
    if strcmp(responses2{i,1},cresponses2{i,1})
        ncorrect=ncorrect+1;
    end
    accuracy(i)=(ncorrect/z)*100;
end

if strcmp(paradigm, 'goal_oriented_paradigm')
    % compute the general accuracy
    varNames={'image','appearance cue (ms)','appearance (ms)',...
        'response time (ms)','response','correct response',...
        'general accuracy (%)'};

    logdata=table(imgList(idxStim),appearanceCue(idxStim),...
        appearance(idxStim),RT(idxStim),responses2,cresponses2,...
        accuracy,'VariableNames', varNames);
else
    % compute the general accuracy
    varNames={'image','appearance fixation (ms)','appearance (ms)',...
        'response time (ms)','response','correct response',...
        'general accuracy (%)'};

    logdata=table(imgList(idxStim),appearanceFixation(idxStim),...
        appearance(idxStim),RT(idxStim),responses2,cresponses2,...
        accuracy,'VariableNames', varNames);
end

%%
writetable(logdata,fullfile(pckdir,content{1,1},strcat('sub-',subID,'_',strcat('run-00',int2str(runint)),'.csv')));

%% check HID device and its keycodes
% devices=PsychHID('Devices');
WaitSecs(10);

while ~keyIsDown
    [keyIsDown,secs,keyCode]=PsychHID('KbCheck',deviceIDTrigger,scanListTrigger);
    if keyIsDown
        tic
        %break;
        disp('Key pressed')
        for i=1:50
            disp(i)
        end
        toc
    end
end


% blue ; keyCode==30 (1)
% yellow; keyCode==31 (2)
% green; keyCode==32 (3)
% red; keyCode==33 (4)
% scanList = keyCode;
