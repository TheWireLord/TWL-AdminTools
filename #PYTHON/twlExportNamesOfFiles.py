import os
import csv

# Get the list of files in the folder
folder_path = '.'  # Replace '.' with the path to your folder if it's not in the current directory
file_names = os.listdir(folder_path)

# Write the file names to a CSV file
csv_file_path = 'file_names.csv'  # Replace 'file_names.csv' with the desired name and path of your CSV file
with open(csv_file_path, 'w', newline='') as csv_file:
    writer = csv.writer(csv_file)
    writer.writerow(['File Names'])
    writer.writerows([[file_name] for file_name in file_names])

print('File names exported to CSV successfully.')