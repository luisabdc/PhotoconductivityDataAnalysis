%==========================================================================
% script to analyze JVTi data
% - takes a folder full of .txt files with V I columns of data, tab
% deliniated along with Header containing temp start and finish values for
% temerature sensors A and B
% - produces .mat file called sample_name.mat containing the following:
% sample name: sample_name.name
% vector of temperature values (length T_n): sample_name.T
% vector of illumination values (length ill_n), sample_name.ill1
% cell array of V vectors and I vectors (each pair have a different
%   length): sample_name.VI
%   the cell array is of size (T_n, ill_n, #) where (T_i, ill_i, 1) is V
%   vector, (T_i, ill_i, 2) is I vector,(T_i, ill_i, 3) is TA and
%   (T_i, ill_i, 4) is TB
% NOTE:  this script relies on the file names having a certain format.
% currently we assume it is: name_IVT_####K_ill#_....
% Tbstart and Tbfinish values are acquired from the Header of the files
%==========================================================================
%function [] = JVTItxttomat_v6(name)
% request sample name from user
name = input('What is the sample name? ', 's');
length_name = length(name);

% folder where VI files live should have format name_IVTraw/
folder_name = [name '_IVTrawtwo/']; %may need to keep _IVT in "name"

% make a list of all files in the folder 
fileList = dir(folder_name);
number_of_files = length(fileList);
%==========================================================================
% Initialize the vectors and cell arrays... we don't know how long they
% will be
T1 = [];     % temperature vector in K 

ill1 = [];   % illumination index vector,(no units, need to use Isc data
             % normalized by Isc under 1-sun at room temp to determine 
             % illumination)
            
VI1 = {};    % cell array to hold all VI vectors

G_ODpercent = [0,1.25,0.365,0.107,0.0200,0.0032,0.000647,1.12,0.329,0.0967,0.0181,0.00289,0.00059,0.834,0.245,0.0716,0.0134,0.00214,0.000446,0.617,0.184,0.0548,0.0103,0.00165,0.000351,0.506,0.153,0.0457,0.00857,0.00138,0.0003,0.296,0.0887,0.0268,0.00499,0.000819,0.000195]; 
fsList = [1,2,1,2,1,2,1,1,2]; % double check with R in summary files
j = 0; 

%==========================================================================
% Start loop to go through all file names
%==========================================================================

for i = 1:number_of_files
    
    % first set of characters in file name should be the same as the name
    if length(fileList(i).name) < length(fileList(4).name)-1
        % there are two random files with name '.' probably related to the 
        % file system. This ignores all files that aren't data files.
        
        warning(['File is too short. Filename is: ' fileList(i).name ' Skipping this file.'])
        
    elseif strcmp(fileList(i).name(1:length_name), name) && ...
           ~strcmp(fileList(i).name(length_name + 2:length_name + 4),'CFG')%CFG part might not be necessary anymore
        % these files are all named correctly

% =========================================================================
% Find indices in string to designate the temperature and illumination
% index, uses the surounding string formating
% =========================================================================   

    % for dark and normal, T starts at 3rd underscore, ill starts at 4th
    % underscore. for testing filters, T starts at 4th and ill starts at
    % 5th
        underscores = strfind(fileList(i).name, '_');
        % only searches for K after the first underscore, to avoid
        % confusion with filename
        K_location = strfind(fileList(i).name(underscores(2)+1:end), 'K');         
        temp_index_begin = underscores(2)+1; % the temperature begins right after the first _
        temp_index_end = underscores(2)+K_location-1; % the temperature ends right before K

        % the illumination index begins right after the 'ill', only searches
        % after third underscore, to avoid confusion with file name
        ill_location = strfind(fileList(i).name(underscores(3) + 1:end), 'ill'); 
        ill_index_begin = underscores(3)+ ill_location + 3; % illumination index begins at O - only second index counts      
        ill_index_end = underscores(4) - 1; % illumination index ends right before the final underscore
        %ill_index of 0 is actually 65535
        
% =========================================================================
% Extract Temperature values from file name and put into T vector
% =========================================================================

        T_temp = str2num(fileList(i).name(temp_index_begin:temp_index_end))/100;

        if i == 1
           T1 = T_temp;
           Ti = 1; % we need this to initialize Ti

        % check if that temperature is already in the T vector
        elseif any(T_temp == T1)
           Ti = find(T_temp == T1); % assign correct index
        else
            T1 = [T1 T_temp];
            Ti = length(T1); % we need this to index the cell array
        end
% =========================================================================
% Extract  illumination index from file name
% =========================================================================

        ill_temp = str2num(fileList(i).name(ill_index_begin:ill_index_end));
        %ill_index of 0 is actually 65535
        if ill_temp==65535
                ill_temp=0;
        end
        %MatLab needs ill to index at 1 for finding values in cell ({V} and
        %{I} values
        ill_new = ill_temp+1;
        %making illumination list
        
        if i == 1
           ill1 = ill_new;
           illi = 1; % we need this to initialize illi
           
        % check if that illumination value is already in the ill vector
        elseif any(ill_new == ill1)
           illi = find(ill_new == ill1); % assign correct index
           
        else
            ill1 = [ill1 ill_new];
            illi = length(ill1); % we need this to index the cell array
            
        end
        
% =========================================================================
% actually pull the IV data out of the file!
%--- will need significant changes for new saving structure (header wth
% Pull IV and T data out of the file
% =========================================================================   
        %fileID = fopen([folder_name fileList(i).name],'r');
        
        startRowVI = 9; % or 17? Will need to know where IV measurements start
        startRowT = 4; % or 7? Don't know if second Enter line will be read
        
        dataArray = importdata([folder_name fileList(i).name],',');
        
        V = dataArray.data(:,1);
        I = dataArray.data(:, 2);
        
       TA = cell2mat(dataArray.textdata(4)); % pulls entire line from dataArray
       TB = cell2mat(dataArray.textdata(5)); % if all lines are spaced by "Enter" TA-7 and TB-9
       
% =========================================================================
% populate the VI cell array
% =========================================================================

        VI1(Ti, ill1(illi), 1) = {V};
        VI1(Ti, ill1(illi), 2) = {I};
        VI1(Ti, ill1(illi), 3) = {TA}; 
        VI1(Ti, ill1(illi), 4) = {TB}; 
    
    
    
    
    else
        % the files do not have the same name as the sample or the names
        % are formatted improperly
        warning(['User input sample name is ' name ' but name of file is ' ...
            fileList(i).name '. Skipping this file.'])
    
    end
    
end
% =========================================================================
% Sort VI, and T so that T is increasing and properly indexed 
% =========================================================================
[T, Tis] = sort(T1); % sort T and save the index values (Tis) that map from 
                     % the old vector to the new vector 

VI = VI1(Tis, :, :); % use index maps to reorder VI cell array

% =========================================================================
% Plots outside of loop!
% =========================================================================

% % indexNum = 0;    
% % tempi = 0;
% % Tn=length(T1);
% % subplotNum = 0;

% % for temp = T1(1:end)
% %     tempi = tempi+1; 


%%=========================================================================
        % all plots - every T and every illumination
%%=========================================================================
% % 
% %  for illum = ill1(1:end)
% %             
% %         % All Plots
% % 
% %         if illum ~= 8         
% %         subplotNum = subplotNum+1;          
% %         
% %             for fsNum = [1,2];
% %          voltage = VI1{tempi,illum,fsNum,1};
% %          current = VI1{tempi,illum,fsNum,2}; 
% %          
% %          subplot(6,4,subplotNum);%Consider: if length(ill1) is even, make rows
% %          % 3 is num of T1 in use
% %             
% %          hold on
% %             
% %          h = plot(voltage,current);
% %          htemp = temp; %maybe put this in legend or somewhere
% %          set(h,'Color',[fsNum-1 0 0]);
% %          title(['T = ', num2str(temp*100), ' ill is ',num2str(G_ODpercent(illum)*100), '%']);
% %             end                                 
% %         end % of all plots        
% %   

%%=========================================================================
        % only one illumination value over every T
%%=========================================================================

% %         subplotNum = subplotNum+1;    
% %         illum = 1;
% %         
% %             for fsNum = [1,2];
% %          voltage = VI1{tempi,illum,fsNum,1};
% %          current = VI1{tempi,illum,fsNum,2}; 
% %          
% %          subplot(3,4,subplotNum);%Consider: if length(ill1) is even, make rows
% %             
% %          hold on
% %             
% %          h = plot(voltage,current);
% %          htemp = temp; %maybe put this in legend or somewhere
% %          set(h,'Color',[fsNum-1 0 0]);
% %                   
% %          title(['T = ', num2str(temp*100), ' ill is ',num2str(G_ODpercent(illum)*100), '%']);
% %             end 
            
            
                        
    %end
%end

%   %puts illumination value in title of each subplot. 
%   subPlotIndex = 0;
%   for titleNum = ill1(1:end)
%       subPlotIndex = subPlotIndex+1;
%       
%       subplot(length(ill1),1,subPlotIndex);%needs to match subplot generated in previous loop
%       titleStr = num2str(titleNum-1);%re-indexes back to 0 for correct illumination value
%       title(titleStr); %consider adding "Illumination: "
%             
%   end

%     for temp = T1(1:end) %first loop runs through every T and records index
%         tempi = tempi+1;
%         subplotNum = 0;
%         for illum = ill1(1:end);%second loop runs through every illumination value and generates plots
%             subplotNum = subplotNum+1;
%             
%             %creating the legend showing temperatures
%             indexNum = indexNum+1;
%             tempString = num2str((temp));
%             
%             if indexNum == 1
%                 legendInput{indexNum} = tempString;
%             elseif legendInput{indexNum-1} == tempString
%                 indexNum = indexNum-1;
%                 %fourth time through, indexNum=2
%             else    legendInput{indexNum} = tempString;
%             end
%             
%             voltage = VI1{tempi,illum,1,1};
%             current = VI1{tempi,illum,1,2};
%             
%             subplot(length(ill1),1,subplotNum);%Consider: if length(ill1) is even, make rows
%             
%             hold on
%             
%             h = plot(voltage,current);
%             htemp = temp; %maybe put this in legend or somewhere
%             set(h,'Color',[(tempi)/(Tn) 0 (Tn-tempi)/(Tn)]);
%             %how do I make the color more sensitive? (full rainbow not just
%             %red to blue
%                         
%         end
%     end
%    
  
% % %     legend(legendInput)
% %     xlabel('Voltage [V]');
% %     ylabel('Current [A]');
    
% =========================================================================
% Save everything
% =========================================================================

%save([folder_name name '.mat'], 'name', 'T', 'ill', 'VI')
mkdir('DataAnalysis') % makes a folder to put extracted.mat files into if it doesn't already exist
save(['DataAnalysis/' name '_extracted.mat'], 'name', 'T', 'ill1', 'VI')
%clear all
% you can open this as a struture by sample_name1 = load(name.mat), and then the
% everthing will be available as sample_name1.T, sample_name1.ill sample_name.VI ect...that
% way you could load more than one sample at the same time
%
% =========================================================================
% Notes for code improvement


% legend should identify first vs second measurement
% color correspond to axis, not T


%fix JVTraw from file name
%expand to multiple figuers and make subplots
%illumination value is title of each subplot
%have temp bar in legend to associate temp to color

%plots with Temperature and light intensity
%all temp for given light intensity
%all light intensity for given temp
%both temp and light intensity on 3D graph
% =========================================================================