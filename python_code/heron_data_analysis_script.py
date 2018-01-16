"""
heron_data_analysis_script

@author: Tyler


Description:
 Loop through all files in data folder and extract, organize and graph data
 HeronDataExtractionFunc() takes file path and returns a structure
     that contains data.variable.times and data.variable.vals
 HeronDataFormatFunc() takes the data structure from above and
     reorganizes it into a structure with Inlet, Outlet, motor,
     turbine and flowmeter fields. Each contains subfields with the
     relevant data such as P,T,h,s for flows and torque,RPM,power.
     Each also contains a times field
 HeronDataGraphingFunc() and HeronDataTableFunc() organize the data
     in the structrure above into graphs and summary tables and saves
     them into the directory from the settings section

"""

## Import Needed packages
import pandas as pd
import CoolProp.CoolProp as CP
import numpy as np
import os  #used to make new folders
import datetime
import heron_data_analysis_functions as hda


## Settings
data_location = r'G:\Tyler Work Folder\Analyses\01_08_18 Heron Turbine Analysis\Test Data'  #full path to folder where all test data is located
data_folder = '2018-01-11'                                                          #folder name within the above folder for data from a single day
save_folder = r'G:\Tyler Work Folder\Analyses\01_08_18 Heron Turbine Analysis\results'  #full path for where you want to save results to
save_figs_flag = False   # 1 if you want to create and save figures, 0 if not. Uses HeronDataGraphingFunc
data_table_flag = True  # 1 if you want to create an excel spreadsheet with summary data, 0 if not. Uses HeronDataTableFunc
reload_data_flag = True
    

## Initialize
#Combine data location and specific data folder to get full path to desired dataset 
data_folder_path = data_location + '\\' + data_folder
#Create new sub folder within save_folder for these results
if save_figs_flag | data_table_flag:
    TimeStamp = ('{:%Y-%m-%d_%H-%M-%S}'.format(datetime.datetime.now()))
    save_path = save_folder + '\\' + data_folder + '_results_' + TimeStamp
    os.makedirs(save_path)
#create empty table for data table to add to
OutputArray = np.array([])
data = []


## Analyze Data
#grab all files in data folder (should all be csv)
data_files_list = os.listdir(data_folder_path)
#data_files_list = data_files_list[15:18]  #can select subset here

#Send each file one at a time to analysis functions and return organized
#data and graphs if desired
for file_ind, filename in enumerate(data_files_list):  #can select a subset of the data here using file_names(3:6) for example
    print('Processing ' + filename)
                                   
    if reload_data_flag:
        file_path = data_folder_path + '\\' + filename
        raw_data = hda.HeronDataExtractionFunc(file_path)
        data.append(hda.HeronDataFormatFunc(raw_data))
    
    #Create and save figures
    if save_figs_flag:
        #add a prefix to the file names of the figures to be saved
        save_name_prefix = save_path + '\\' + filename
        #the data and the save name are then sent to the function 
        #and the figures are created and saved within
        hda.HeronDataGraphingFunc(data[file_ind], save_name_prefix, save_figs_flag )
    
    #Create summary data table
    if data_table_flag:
        OutputArray, ColHeaders = hda.HeronDataTableFunc(data[file_ind], filename, OutputArray)
        #OutputArray contains the numerical values with rows for
        #each entry, ColHeaders contains the variable descriptions
        #for each column of data

 
## Finishing Touches
#Create data table and export to excel
if data_table_flag:
    #Compile table data and column headers into a single table
    AnswerTable = pd.DataFrame(OutputArray)
    AnswerTable.columns = ColHeaders
    AnswerTable = AnswerTable.replace('nan', '', regex=True)
    #save to excel
    AnswerTable.to_excel(save_path + '\DataTable.xlsx')
        
