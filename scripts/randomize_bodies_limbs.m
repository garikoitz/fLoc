basedir='/Users/tiger/toolboxes/fLoc/stimuli';
% Define the folder paths
sourceFolder = [basedir '/Bodies']; % The folder with the original 288 files
targetFolder = [basedir '/Bodies2']; % The new folder where you want to save 144 files

% Get all the files in the source folder
files = dir(fullfile(sourceFolder, 'Bodies*.*'));

d = dir(fullfile(sourceFolder, 'Bodies*.*'));
n = {d.name};
t_char = regexp(n,'\-?[\d\.]+$','match','once');
t_num = str2double(t_char);
[~,idx] = sort(t_num);
d_sort = d(idx);

files = files(~[files.isdir]); % Exclude directories
numFiles = length(files);

% Check if there are 288 files
if numFiles < 288
    error('There are less than 288 files in the folder');
end

% Split the files into two groups
group1 = files(1:144);
group2 = files(145:288);

% Randomly select 72 files from each group
idx1 = randperm(144, 72);
idx2 = randperm(144, 72);

selectedFilesGroup1 = group1(idx1);
selectedFilesGroup2 = group2(idx2);

% Combine the selected files into one array
selectedFiles = [selectedFilesGroup1; selectedFilesGroup2];

% Shuffle the combined array of selected files
shuffledFiles = selectedFiles(randperm(length(selectedFiles)));

% Ensure the target folder exists
if ~exist(targetFolder, 'dir')
    mkdir(targetFolder);
end

% Copy the selected and shuffled files to the new folder with renamed files
for i = 1:length(shuffledFiles)
    % Get the source file path
    sourceFile = fullfile(shuffledFiles(i).folder, shuffledFiles(i).name);
    
    % Create the target file name and path
    [~, ~, ext] = fileparts(shuffledFiles(i).name);
    targetFile = fullfile(targetFolder, sprintf('%d%s', i, ext));
    
    % Copy the file to the new folder
    copyfile(sourceFile, targetFile);
end

disp('Files have been successfully copied and renamed.');