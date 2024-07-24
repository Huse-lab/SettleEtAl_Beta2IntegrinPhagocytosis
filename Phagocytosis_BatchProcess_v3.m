%% Select Folder For Processing
fprintf('Please select folder of interest containing czi files \n')
file_path = uigetdir('Select Folder of interest');

current_dir = pwd;
cd(file_path);
files = dir(file_path);
%% Initialize Settings/Parameters
input_t = inputdlg('Input the time interval for this experiment (in seconds)');
t_interval = str2num(input_t{1});
input_an = inputdlg('Input the interval of frames to analyze (1 if all)');
an_interval = str2num(input_an{1});

%Confirm Channel Identities
input_channels = inputdlg('Input Number of Channels','Channels',1,{'4'});
num_channels = str2num(input_channels{1});
%input_channelID = inputdlg({'DAPI','FITC','TRITC','Brightfield'},'Define Channels, set empty channels to 0',1,{'1','2','3','4'});


file_list = {};

for file = files'
    if contains(file.name,'.czi')
        file_list = [file_list file.name];
    end
end

%%
SkipAll = false;
ProcessAll = false;

for file_name = file_list
    outmat = strrep(file_name{1},'.czi','_frameStruct.mat');
    

    if isfile(outmat) && ~(ProcessAll || SkipAll)
        quest = [outmat ' already exists, would you like to skip or re-process?'];
        answer = listdlg('ListString',{'Reprocess','Reprocess All','Skip',...
            'Skip All'},'PromptString', quest)
        switch answer
            case 1

            case 2
                ProcessAll = true;

            case 3
                continue

            case 4
                disp(4)
                SkipAll = true;
                continue
                

            otherwise 
                error('Error: Please select one option')
    
        end
    end
    fileinfo = czifinfo(file_name{1});
    data = bfopen(file_name{1});


    num_channels = max([fileinfo.sBlockList_P0.CStart])+1;
    num_frames = max([fileinfo.sBlockList_P0.TStart])+1;
    stack = data{1, 1};
    
    if num_channels == 4
        frameStruct = struct('Channel1',[],...
        'Channel2',[],'Circles2',{},'Channel3',[],'Channel0',[],...
        'xDim',[],'yDim',[],'LabeledImage',[],'Stats',table(), ...
        'TimeStamp',[],'Num_Cells',[]);
    elseif num_channels == 3
        frameStruct = struct('Channel1',[],...
        'Channel2',[],'Circles2',{},'Channel3',[],...
        'xDim',[],'yDim',[],'LabeledImage',[],'Stats',table(), ...
        'TimeStamp',[],[]);


    
    num_channels = cast(max([fileinfo.sBlockList_P0.CStart])+1,'double');
    num_frames = cast(max([fileinfo.sBlockList_P0.TStart])+1,'double');
    stack = data{1, 1};


    wait = waitbar(0,'Please wait...');
    disp(file_name)
    
    for t = 0:num_frames-1              % loop through each frame
        if mod(t,an_interval) ~= 0
            continue
        end


        waitbar(t/num_frames,wait,...
            ['Processing Frame... ' num2str(t)] )
        time_indx = [fileinfo.sBlockList_P0.TStart]==t;
        framedata = stack(time_indx,1);
        frameinfo = ...
            fileinfo.sBlockList_P0(time_indx);
        
        frame = processFrame(stack,fileinfo,t);
        frame.TimeStamp = t*t_interval;
        frameStruct(t+1) = frame;
        
    
    
        
    
    end
    

empty_indx = cellfun(@isempty,({frameStruct.xDim}));
frameStruct = frameStruct(~empty_indx)

frameStruct = rmfield(frameStruct, {'Channel1','Channel2','Channel3'});
save(outmat,'frameStruct','-v7.3');
clear('frameStruct','data');
close(wait)
end

%% 
files = dir(file_path);
mat_list = {};
for file = files'
    if contains(file.name,'_frameStruct.mat')
        mat_list = [mat_list file.name];
    end
end
load(mat_list{1});
ph_index_array = zeros(length([frameStruct(:).TimeStamp]),length(mat_list)+1);
ph_index_array(:,1) = [frameStruct(:).TimeStamp]';

ph_eff_array = zeros(length([frameStruct(:).TimeStamp]),length(mat_list)+1);
ph_eff_array(:,1) = [frameStruct(:).TimeStamp]';

for i = 2:length(mat_list)+1
    disp(['Loading ' mat_list{i-1}])
    load(mat_list{i-1});
    ph_index_array(:,i) = [frameStruct(:).Phagocytic_Index]';
    ph_eff_array(:,i) = [frameStruct(:).Num_Cells]';

end

tbl = array2table(ph_index_array,"VariableNames",[{'Time (s)'} mat_list]);
%%
writetable(tbl,'AHS4_102_PhagocyticIndex.csv')


%% Create "Report" 
files = dir(file_path);
mat_list = {};
for file = files'
    if contains(file.name,'_frameStruct.mat')
        mat_list = [mat_list file.name];
    end
end
load(mat_list{1});
expStats = cell(length(mat_list),1)

for i = 1:length(mat_list)
    sampleStats = makeSampleReport(mat_list{i},1);
    i
    out_png = strrep(mat_list{i},'_frameStruct.mat','_Report.png');
    saveas(gcf,out_png)
    close
    expStats{i} = sampleStats;

end 


%% Output Tables

ph_eff_array = zeros(length([frameStruct(:).TimeStamp]),length(mat_list)+1);
ph_eff_array(:,1) = [frameStruct(:).TimeStamp]';
ph_num_array = zeros(length([frameStruct(:).TimeStamp]),length(mat_list)+1);
ph_num_array(:,1) = [frameStruct(:).TimeStamp]';
numparticles_array = zeros(length([frameStruct(:).TimeStamp]),length(mat_list)+1);
numparticles_array(:,1) = [frameStruct(:).TimeStamp]';
numcells_array = zeros(length([frameStruct(:).TimeStamp]),length(mat_list)+1);
numcells_array(:,1) = [frameStruct(:).TimeStamp]';


for i = 2:length(mat_list)+1
    
    ph_eff_array(:,i) = expStats{i-1}.PercentAcidified;
    ph_num_array(:,i) = expStats{i-1}.NumAcidified;
    numcells_array(:,i) = expStats{i-1}.NumCells;
    numparticles_array(:,i) = expStats{i-1}.NumParticles;
end
tbl = array2table(ph_eff_array,"VariableNames",[{'Time (s)'} mat_list]);
tbl2 = array2table(ph_num_array,"VariableNames",[{'Time (s)'} mat_list]);
tbl3 = array2table(numparticles_array,"VariableNames",[{'Time (s)'} mat_list]);
tbl4 = array2table(numcells_array,"VariableNames",[{'Time (s)'} mat_list]);

writetable(tbl,'BatchOutput_PhagocyticEfficiency.csv')
writetable(tbl2,'BatchOutput_NumberAcidified.csv')
writetable(tbl4,'BatchOutput_TotalParticles.csv')
writetable(tbl4,'BatchOutput_NumCells.csv')