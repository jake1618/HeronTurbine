%heron_raw_data_analysis

%Desciption:
    % Script designed to take raw data from Heron Turbine testing and evaluate
    % performance. Loops through all files in a given data folder and 
    % extracts, organizes and graphs data
    
%How to Use:
    %1) Choose location of data to analyze, location to save data and flags
        %for run in the Settings section
    %2) Choose window of data analysis in HeronDataTableFunc()
    %3) Run the script
    
    
%Functions Used:
    % HeronDataExtractionFunc() takes file path and returns a structure
        % that contains data.variable.times and data.variable.vals
    % HeronDataFormatFunc() takes the data structure from above and
        % reorganizes it into a structure with Inlet, Outlet, motor,
        % turbine and flowmeter fields. Each contains subfields with the
        % relevant data such as P,T,h,s for flows and torque,RPM,power.
        % Each also contains a times field
    % HeronDataGraphingFunc() and HeronDataTableFunc() organize the data
        % in the structrure above into graphs and summary tables and saves
        % them into the directory from the settings section

%Revision History
    %Version: Rev01 | Date: 01/09/18 | Author: Tyler Ketchem (BEST)

%Copyright 2018 Bright Energy Storage Technologies LLP
%

%% Settings
    data_location = 'G:\Tyler Work Folder\Analyses\01_08_18 Heron Turbine Analysis\Test Data';  %full path to folder where all test data is located
    data_folder = '2018-01-11';                                                          %folder name within the above folder for data from a single day
    save_folder = 'G:\Tyler Work Folder\Analyses\01_08_18 Heron Turbine Analysis\results';  %full path for where you want to save results to
    save_figs_flag = 0;   % 1 if you want to create and save figures, 0 if not. Uses HeronDataGraphingFunc
    data_table_flag = 1;  % 1 if you want to create an excel spreadsheet with summary data, 0 if not. Uses HeronDataTableFunc
    reload_data_flag = 0;
    
%% Initialize
    %Combine data location and specific data folder to get full path to desired dataset 
    data_folder_path = [data_location '\' data_folder];
    %Create new sub folder within save_folder for these results
    if save_figs_flag || data_table_flag
        save_path = [save_folder '\' data_folder '_results'];
        mkdir(save_path)
    end
    %create empty table for data table to add to
    OutputArray = {}; 

    
%     % Create New Directory For Saving into
%     if MakePowerPoint || SaveFigs || MakeDataTable
%         clk = clock;
%         date_time = [num2str(clk(1)), '_', num2str(clk(2)), '_', num2str(clk(3)), '-', num2str(clk(4)), '_', num2str(clk(5))];
%         ParentDirectory = cd;
%         SaveFolder = [ParentDirectory,'\CE_Runs_',date_time];
%         mkdir(SaveFolder)   
%     end

%% Grab and Analyze Data Files
    % Loop through all files in data folder and extract, organize and graph data
    % HeronDataExtractionFunc() takes file path and returns a structure
        % that contains data.variable.times and data.variable.vals
    % HeronDataFormatFunc() takes the data structure from above and
        % reorganizes it into a structure with Inlet, Outlet, motor,
        % turbine and flowmeter fields. Each contains subfields with the
        % relevant data such as P,T,h,s for flows and torque,RPM,power.
        % Each also contains a times field
    % HeronDataGraphingFunc() and HeronDataTableFunc() organize the data
        % in the structrure above into graphs and summary tables and saves
        % them into the directory from the settings section

    %grab all files in data folder (should all be csv)
        data_files_list = dir(data_folder_path);
        file_names = {};
        for ind = 3:length(data_files_list)
           file_names{end+1} = [data_folder_path '\' data_files_list(ind).name];
        end

    %Send each file one at a time to analysis functions and return organized
    %data and graphs if desired
        for file_ind = 1:length(file_names)  %can select a subset of the data here using file_names(3:6) for example
            if reload_data_flag
                raw_data{file_ind} = HeronDataExtractionFunc(file_names{file_ind});
                data{file_ind} = HeronDataFormatFunc(raw_data{file_ind});
            end            
            
            %Grab name of data file
                %first the name of the data file is extracted from the full
                %file path by looking at the '\' characters that separate
                %the different aspects of the file name
                data_name_index = strfind(file_names{file_ind},'\'); data_name_index = data_name_index(end);
                data_name = file_names{file_ind}(data_name_index+1:end-4);
            
            %Create and save figures
            if save_figs_flag
                %add a prefix to the file names of the figures to be saved
                save_name_prefix = [save_path '/' data_name];
                %the data and the save name are then sent to the function 
                %and the figures are created and saved within
                HeronDataGraphingFunc(data{file_ind}, save_name_prefix, save_figs_flag )
            end
            
            %Create summary data table
            if data_table_flag
                disp(data_name)
                [OutputArray, ColHeaders] = HeronDataTableFunc(data{file_ind}, data_name, OutputArray);
                %OutputArray contains the numerical values with rows for
                %each entry, ColHeaders contains the variable descriptions
                %for each column of data
            end
            
        end
        
%% Finishing Touches
    %Create data table and export to excel
    if data_table_flag
        %Compile table data and column headers into a single table
        [NumRows, NumCols] = size(OutputArray);
        AnswerTable(1,1:NumCols) = ColHeaders;
        AnswerTable(2:NumRows+1,1:NumCols) = OutputArray;
        %Save to Excel File
        xlswrite([save_path,'\DataTable.xlsx'],AnswerTable)
    end


