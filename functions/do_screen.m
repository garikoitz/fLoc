function [w, center] = doScreen
% Opens a full-screen window, sets text properties, and hides the cursor.
% Written by KGS Lab
% Edited by AS 8/2014


%{

params.BackgroundFullscreenColor = 128; % 0=Black, 255=White
params.calibration      = []; % Was calibrated with Photometer
params.stimSize         = 'max';
params.skipCycleFrames  = 0;
params.display.frameRate         = 60;





params.display.gammaTable = [linspace(0,1,256);linspace(0,1,256);linspace(0,1,256)]';
params.runPriority      =  7;





KbCheck;GetSecs;WaitSecs(0.001);

%try
% check for OpenGL
AssertOpenGL;

% to skip annoying warning message on display (but not terminal)
%Screen('Preference', 'Verbosity', 2);
Screen('Preference', 'VisualDebugLevel', 0);
Screen('Preference','SkipSyncTests', 1);

% Open the screen
params.display                = openScreen(params.display);
params.display.devices        = params.devices;

% to allow blending
Screen('BlendFunction', params.display.windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
%}









% open window and find center
Screen('Preference', 'SkipSyncTests', 1)
Screen('Preference','VisualDebugLevel', 3)
S = Screen('Screens');
screen_num = max(S);
[w, rect] = Screen('OpenWindow', screen_num);
center = rect(3:4) / 2;

% set text properties
Screen('TextFont', w, 'Times');
Screen('TextSize', w, 24);
Screen('FillRect', w, 128);

% hide cursor
HideCursor;








end
