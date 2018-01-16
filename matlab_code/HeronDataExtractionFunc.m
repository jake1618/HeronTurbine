function [ output_args ] = HeronDataExtractionFunc(filepath)
%HeronDataExtractionFunc Takes heron data filepath, extracts and returns
%data
%   grabs data using the filepath and formats it into a cell array with 
%   each field being the name of the variable and having .times and .vals 
%   fields. Also pulls the rpm from the name of the file, must be located
%   towards the end



%% Initialize needed variables to find data in file
    startRow = 19;  %this is Brendan's original value...
    HeaderRow = 7;  %This is number of row in csv file headers start on
    endRow = inf;
    delimiter = '\t';
    byteL = 323; % # of bytes to jump to find channel name data
    ErrorOccurred = 0;

%% Extract data
    %Open File
        fileID = fopen(filepath);    
        if fileID == -1
            error('Could not open file!')
            disp(fname{i})
        end

    %Grab column header info
        for q = 1:(HeaderRow-1); fgetl(fileID); end %Points to the right header row somehow
        headerLine = fgetl(fileID);
        nCh = length(find(headerLine==sprintf('\t')));  %this includes "Name" columns (see below)
        headerLine = strsplit(headerLine); % convert to cell array
        headerLine(end) = [];              %gets rid of last empty cell
        frewind(fileID);  %frewind(FID) sets the file position indicator to the beginning of the file associated with file identifier FID.

        %Should now have something like this for HeaderLine
        %{'Name','bMagnetEnable','Name','bMagnetFansEnable'...'Name','rPI8','Name','rPI9'...}

	%Scan & extract data to create 'dataArray'-------------------------
        %Generate formatting array (controls format & # of columns)
            formatSpec = '%s';
            for ii = 2:nCh-1
                formatSpec = [formatSpec '%s'];
            end
            formatSpec = [formatSpec '%[^\n\r]'];
        %Extract data into cell array
            textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
            dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'ReturnOnError', false);
            disp('Data extracted, processing...')            
        %We end up with dataArray being a cell array with each entry
        %containing a vector of the data in the respective column. All
        %data has the same length due to empty cells being included.
        %Note that the values are string type variables at this point
        
    %Convert to our desired data format
        %the data in each 'name' column is the time data for the variable
        %in the next column
        for j = 2:2:nCh  %go by two to treat times and values as pair
            indx = ~cellfun(@isempty,dataArray{j}); % Scan for empty cells
            indx(end-1:end) = false; % ensure ignoring of last two lines (usually empty)
        %Convert strings to numbers
            if j ~= nCh
                temp_vals = dataArray{j}(indx);
                temp_vals = reshape(sscanf(sprintf('%s#', temp_vals{:}), '%g#'), size(temp_vals)); % faster replacement for str2double
                temp_times = dataArray{j-1}(indx);  %times are column before
                temp_times = reshape(sscanf(sprintf('%s#', temp_times{:}), '%g#'), size(temp_times)); % faster replacement for str2double
            else %necessary??
                temp_vals = str2double(dataArray{j}(indx)); % use str2double for last column since it may contain tabs
                temp_times = str2double(dataArray{j-1}(indx)); % use str2double for last column since it may contain tabs
            end
            temp_vals(isnan(temp_vals)) = []; % Delete any leftover blanks
            temp_times(isnan(temp_times)) = []; % Delete any leftover blanks
            temp_times = temp_times/1000;  % convert to seconds from milliseconds
        %Creates each variable based on headerLine name, then clears temps
            eval(['results.' headerLine{j} '.vals = temp_vals;'])
            eval(['results.' headerLine{j} '.times = temp_times;'])
            clear temp_vals temp_times indx
        end
        
    %downsample torque values
        results.rTorqueHUTAvg_1k.times = results.rTorqueHUTAvg.times(1:10:end);
        results.rTorqueHUTAvg_1k.vals = results.rTorqueHUTAvg.vals(1:10:end);
        
    %pull rpm from data file name
        %find 'rpm' in the name string and pull out the number before it
        rpm_indices = [strfind(filepath,'rpm')-5:strfind(filepath,'rpm')-2];
        if isempty(strfind(filepath,'rpm'))
            results.rpm = 0;
        else
            results.rpm = str2double(filepath(rpm_indices));
        end
            
        results.data_location = filepath;


%% Format final outputs
    output_args = results;

end

