
%lang={'ES','EU','JP'};
%stim={'CB','SC','FF','CS','word'};
basedir='/Users/tiger/toolboxes/fLoc/stimuli';
category={'Bodies', 'Faces'};
set1={'body','adult'};
set2={'limb','child'};

for cati = 1: length(category)

    % cat=sprintf('%s_%s',lang{lan},stim{sti});
    
    % Define folder paths
    cat=category{cati};
    folder1 = [basedir '/' set1{cati}]; % Change to your actual path
    folder2 =  [basedir '/' set2{cati}]; % Change to your actual path
    destinationFolder =  [basedir '/' category{cati}]; % Change to your actual destination path
    
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
        copyfile(sourceFile, destFile);
    end
    
    % Move and rename files from ES_CB2, continuing the numbering
    for i = 1:length(files2)
        sourceFile = fullfile(folder2, files2(i).name);
        destFile = fullfile(destinationFolder, sprintf([cat '-%d.jpg'], length(files1) + i));
        copyfile(sourceFile, destFile);
    end
    output=sprintf('Files moved and renamed %s successfully!',cat);
    disp(output);

end 

