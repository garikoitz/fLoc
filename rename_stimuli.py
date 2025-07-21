import os
# rename all the language codes:
langs=['JP','IT','EN']
cats=['RW','CS','FF','SC']

basedir='/Users/tiger/toolboxes/fLoc/stimuli'


def rename_folder_and_files(base_dir, old_folder_name, new_folder_name):
    """
    Renames a folder and all files inside it, ensuring they match the new folder name.

    Parameters:
    - base_dir (str): The directory where the folder is located.
    - old_folder_name (str): The existing folder name to be renamed.
    - new_folder_name (str): The new name for the folder and its files.
    """
    
    old_folder_path = os.path.join(base_dir, old_folder_name)
    new_folder_path = os.path.join(base_dir, new_folder_name)

    # Ensure the folder exists
    if not os.path.exists(old_folder_path):
        print(f"Error: Folder '{old_folder_name}' not found in '{base_dir}'.")
        return

    # List and sort files
    files = sorted([f for f in os.listdir(old_folder_path) if os.path.isfile(os.path.join(old_folder_path, f))])

    # Rename files inside the folder
    for idx, file_name in enumerate(files, start=1):
        file_ext = os.path.splitext(file_name)[1]  # Get file extension (e.g., .jpg)
        new_file_name = f"{new_folder_name}-{idx}{file_ext}"
        old_file_path = os.path.join(old_folder_path, file_name)
        new_file_path = os.path.join(old_folder_path, new_file_name)
        os.rename(old_file_path, new_file_path)
        print(f"Renamed file: {file_name} → {new_file_name}")

    # Rename the folder itself
    os.rename(old_folder_path, new_folder_path)
    print(f"Renamed folder: {old_folder_name} → {new_folder_name}")

# Example Usage:
# Replace "your_directory" with the actual parent directory containing the folders.

for lang in langs:
    for cat in cats:
        rename_folder_and_files(basedir, f"{lang}_{cat}", f"{lang}_{cat}1")