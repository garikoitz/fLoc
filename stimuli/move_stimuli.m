basedir='';
categ='ES_CB';
lang={'ES','EU','JP'};
stim={'CB','SC','FF','CS','word'};
for lan = 1: length(lang)
    for sti = 1:length(stim)
    cat=sprintf('%s_%s',lang{lan},stim{sti});
    % Define folder paths
    folder1 = ['./' cat '1']; % Change to your actual path
    folder2 =  ['./' cat '2']; % Change to your actual path
    destinationFolder =  ['./' cat]; % Change to your actual destination path
    
    % Create the destination folder if it doesn't exist
    if ~exist(destinationFolder, 'dir')
        mkdir(destinationFolder);
    end
    
    % Get list of files in both folders
    files1 = dir(fullfile(folder1, '*.jpg'));
    files2 = dir(fullfile(folder2, '*.jpg'));
    
    % Move and rename files from ES_CB1
    for i = 1:length(files1)
        sourceFile = fullfile(folder1, files1(i).name);
        destFile = fullfile(destinationFolder, sprintf([cat '-%d.jpg'], i));
        movefile(sourceFile, destFile);
    end
    
    % Move and rename files from ES_CB2, continuing the numbering
    for i = 1:length(files2)
        sourceFile = fullfile(folder2, files2(i).name);
        destFile = fullfile(destinationFolder, sprintf([cat '-%d.jpg'], length(files1) + i));
        movefile(sourceFile, destFile);
    end
    output=sprintf('Files moved and renamed %s successfully!',cat);
    disp(output);
    end 
end 

