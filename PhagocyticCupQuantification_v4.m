%%
%V4 uses Lng files for thresholding and identification and then calculates
%accumulation ratios of the Raw data and the Lng data
fprintf('Please select folder of interest containing czi files \n')
file_path = uigetdir('Select Folder of interest');

current_dir = pwd;
cd(file_path);
files = dir(file_path);

file_list = {};
LNG_list = {};

for file = files'
    if contains(file.name,'Lng.tif')
        LNG_list = [LNG_list file.name];
    elseif contains(file.name,'1.tif')
        file_list = [file_list file.name];
    end
end

%check for missing pairs
for file = LNG_list
    checkname = strrep(file{1},'_Lng','');
    checkLNG = ismember(checkname,file_list);
    switch checkLNG
        case 0
            warning(['Warning: File List contains ' file{1} ...
                ', but not ' checkname]);
    end
end
for file = file_list
    checkname = strrep(file{1},'001.tif','001_Lng.tif');
    checkLNG = ismember(checkname,LNG_list);
    switch checkLNG
        case 0
            warning(['File List contains ' file{1} ...
                ', but not ' checkname]);
    end
end



%% Initial parameters and give assumptions


fprintf('Reading first file to set initial parameters....')
disp(LNG_list{1})

data = bfopen(LNG_list{1});
metadata = data{1,4};
data_table = organizeTIF(data);

%user input to define the channels
channels = unique(data_table.Channel);
figure
for k = channels'
    subplot(1,length(channels),k)
    testchannel = tableofImagestoArray(data_table{data_table{:,3} == k,1});
    imagesc(testchannel(:,:,round(size(testchannel,3)/2)));
    axis equal
    axis off
    title(num2str(k))
end
particleChannel = inputdlg('What channel is the particle','Channel Select',1,{'1'});
particleChannel = str2num(particleChannel{1});
close()
numStains = length(channels)-1;
% check for second stain
if numStains > 1
    figure
    for k = channels'
        subplot(1,length(channels),k)
        testchannel = tableofImagestoArray(data_table{data_table{:,3} == k,1});
        imagesc(testchannel(:,:,round(size(testchannel,3)/2)));
        axis equal
        axis off
        title(num2str(k))
    end
    cellChannel = inputdlg('What channel to use to mask the Cell','Channel Select',1,{'3'});
    cellChannel = str2num(cellChannel{1});
else 
    cellChannel = 2;
end
    

close all

%create the empty table row

sz = [1,5+(numStains)*8];
varTypes = ["string","double","double","double","double"];
varNames = ["FileName","ParticleID","FractionEngulfed",...
    "StainCorrelation_Total","StainCorrelation_onParticle"];
for i = 1:numStains
    varTypes = [varTypes, "double","double","double","double",...
        "double", "double","double","double"];
    varNames = [varNames, "TotalStain"+num2str(i), "TotalStainRaw"+num2str(i), ...
        "ParticleStain"+num2str(i), "ParticleStainRaw"+num2str(i), ...
        "FloorStain"+num2str(i), "FloorStainRaw"+num2str(i),...
        "NonFloorStain"+num2str(i), "NonFloorStainRaw"+num2str(i)];
end
blankresultRow = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);


%% Main Loop
outTable = blankresultRow;
for filename = LNG_list
    tic
    disp(filename)
    data = bfopen(filename{1});
    filenameRaw = char(strrep(filename{1},"_Lng",""));
    dataRaw = bfopen(filenameRaw);
    metadata = data{1,4};
    channels_array = datatoChannelsArray(data,particleChannel,numStains);
    channels_arrayRaw = datatoChannelsArray(dataRaw,particleChannel,numStains);
    xDim = size(channels_array{1},1);
    yDim = size(channels_array{1},2);
    zDim = size(channels_array{1},3);

    %Identify Particles
    threshold1 = max(channels_array{1},[],'all') / 10;
    bw1 = imbinarize(channels_array{1},threshold1);
    [L,n] = bwlabeln(bw1,26);
    rp3 = regionprops3(L);
    [largestV, idx] = max(rp3.Volume);
    %largeParticles = rp3(rp3.Volume > largestV*0.5,:);

    for i = 1:height(rp3)
        if rp3(i,:).Volume > largestV*0.5
            particleID = i;
%        particleCentroid = largeParticles(i,:).Centroid;
%         particleBoundingBox = largeParticles(i,:).BoundingBox;
%         crop_boundariesX = round([particleCentroid(1)-0.7*particleBoundingBox(4), ...
%             particleCentroid(1)+0.7*particleBoundingBox(4)]);
%         crop_boundariesY = round([particleCentroid(2)-0.7*particleBoundingBox(5), ...
%             particleCentroid(2)+0.7*particleBoundingBox(5)]);
%         
%         crop_boundariesX(crop_boundariesX < 1) = 1;
%         crop_boundariesX(crop_boundariesX > xDim) = xDim;
% 
%         crop_boundariesY(crop_boundariesY < 1) = 1;
%         crop_boundariesY(crop_boundariesX > yDim) = yDim;
            singleparticlemask = zeros(size(L));
            singleparticlemask(L == i) = 1;

            particleShellmask = logical(makeShellMask(singleparticlemask,5));
            
    
            mask2 = makeInteriorMask(channels_array{cellChannel});
            se = strel('disk',5);
            maskclosed = imclose(mask2,se);
            maskfilled = maskclosed;
            for k = 1:size(maskclosed,3)
                maskfilled(:,:,k) = imfill(maskclosed(:,:,k),"holes");
            end
            
            cell_rp3 = regionprops3(maskfilled);
            [V, idx2] = max(cell_rp3.Volume);
            cell_mask_centroid = cell_rp3(idx2,:).Centroid;
            [~,zeroisbot] = min(dist(cell_mask_centroid(:,3),[0,zDim]));
            particleZ_array = sum(particleShellmask,[1,2]);
            particleZ_array = [particleZ_array(:)]>0;
            if zeroisbot == 1
                bottomhalfarray = zeros(1,zDim)';
                bottomhalfarray(1:floor(cell_mask_centroid(3))) = 1;
            else
                bottomhalfarray = zeros(1,zDim)';
                bottomhalfarray(ceil(cell_mask_centroid(3)):end) = 1;
            end

            floor_zone = bitand(~particleZ_array,bottomhalfarray);
            floor_mask = maskfilled;
            floor_mask(:,:,~floor_zone) = 0;

            newRow = blankresultRow;

            for j = 1:numStains
                channel = channels_array{j+1};
                channelRaw = channels_arrayRaw{j+1};
                newRow.("TotalStain"+num2str(j)) = mean(channel(maskfilled));
                newRow.("ParticleStain"+num2str(j)) = mean(channel(bitand(maskfilled,particleShellmask)));
                newRow.("FloorStain"+num2str(j)) = mean(channel(floor_mask));
                newRow.("NonFloorStain"+num2str(j)) = mean(channel(bitand(maskfilled,~floor_mask)));
                newRow.("TotalStainRaw"+num2str(j)) = mean(channelRaw(maskfilled));
                newRow.("ParticleStainRaw"+num2str(j)) = mean(channelRaw(bitand(maskfilled,particleShellmask)));
                newRow.("FloorStainRaw"+num2str(j)) = mean(channelRaw(floor_mask));
                newRow.("NonFloorStainRaw"+num2str(j)) = mean(channelRaw(bitand(maskfilled,~floor_mask)));

            end

            if numStains == 2
                newRow.StainCorrelation_Total = corr(channels_array{2}(maskfilled),channels_array{3}(maskfilled));
                newRow.StainCorrelation_onParticle = corr(channels_array{2}(particleShellmask),channels_array{3}(particleShellmask));
            end

    
            fractionEngulfed = sum(maskfilled&particleShellmask,'all')/ ...
                sum(particleShellmask,'all');



            newRow.FileName = filename;
            newRow.ParticleID = particleID;
            newRow.FractionEngulfed = fractionEngulfed;
    
            outTable = [outTable; newRow];
        end

    end
    toc
    
    %particleshellmask = makeShellMask(singlemask,5);







end

writetable(outTable,'DemoResults.csv')
%channels_array = datatoChannelsArray(data,1,1);


%% Functions

function data_table = organizeTIF(data)
stack_size = size(data{1},1);

sz = [stack_size,4];
varTypes = ["cell","double","double","double"];
varNames = ["Image","Z","Channel","Particle_ID"];
data_table = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

for k = 1:stack_size
    image = data{1}{k,1};
    image_label = data{1}{k,1};
    Zsub1 = strsplit(data{1}{k,2},'Z?=');
    Zsub2 = strsplit(Zsub1{2},'/');
    Z_data = str2num(Zsub2{1});

    Csub1 = strsplit(data{1}{k,2},'C?=');
    Csub2 = strsplit(Csub1{2},'/');
    C_data = str2num(Csub2{1});

    data_table(k,1) = {image};
    data_table(k,2) = {round(Z_data)};
    data_table(k,3) = {round(C_data)};
    data_table(k,4) = {1};
end

end


function array = tableofImagestoArray(table)
    array = zeros(size(table{1},1),size(table{1},2),length(table));
    for k = 1:length(table)
        array(:,:,k) = table{k};
    end

end

function out_channels = datatoChannelsArray(data,particleChannel,numStains)
data_table = organizeTIF(data);
out_channels{1} = tableofImagestoArray(data_table{data_table{:,3} == particleChannel,1});
stainChannels = setxor(1:numStains+1,particleChannel);
k=1;
for i = stainChannels
    out_channels{1+k} = tableofImagestoArray(data_table{data_table{:,3} == i,1});
    k=k+1;
end
end

function mask = makeShellMask(bw,pixels_dilated)
mask = zeros(size(bw));

for k = 1:size(bw,3)
    bwslice = bw(:,:,k);
    se= strel("disk",pixels_dilated);
    dilated = imdilate(bwslice,se);
    shell = dilated-bwslice;
    mask(:,:,k) = shell;

end
end


function mask = makeInteriorMask(slicearray)
mask = zeros(size(slicearray));
T = graythresh(rescale(slicearray));
threshold = T*max(slicearray,[],'all');
mask = imbinarize(slicearray,threshold);
mask = imfill(mask,'holes');

end
