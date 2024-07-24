%% Load .tif Files

[data,~,FileName,PathName] = ReadBFImages();
% if READBFImages runs an error, try to set the path to the
% DaanParticleanalysis in the Github repo in the Manuscripts folder

%% Extract the images and required metadata

if exist('OGdata','var'); data = OGdata;  end
[MPStats,data1                ] = Extract_Essential_Metadata(data,FileName,PathName,1);
[IM3D_MP,LLSMMask,zcorrfactor] = Extract_Images(data1,MPStats,MPStats(1).MPchannel);

[MPStats.IM3D                 ] = IM3D_MP{:};
[MPStats.LLSMMask             ] = LLSMMask{:};
[MPStats.PixelSizeZ_original  ] = MPStats.PixelSizeZ;
[MPStats.PixelSizeZ           ] = ArraytoCSL([MPStats.PixelSizeZ]/zcorrfactor);
[MPStats.zcorrFactor          ] = deal(zcorrfactor);

MPStats = getStainChannel(MPStats);
if length(MPStats(1).StainChannels) == 1
    [IM3DCell,~,~] = Extract_Images(data1,MPStats,MPStats(1).StainChannels);
else
    [IM3DCell,~,~] = Extract_Images(data1,MPStats,MPStats(1).StainChannels(2));
end
[MPStats.IMStain                 ] = IM3DCell{:};

MPStats = orderfields(MPStats);
if ~all(size(data)==size(data1));     OGdata = data;     data = data1;       end        
clear('IM3D_MP','IM3DCell','LLSMMask','zcorrfactor','data1');

%% Run Main Loop

out = Cup_Tracing_GUI(MPStats)
CupStats = out;

for i = 1:length(CupStats)
CupStats(i).FileName = MPStats(i).FileName;
end

%% Define Savename and Save Struct
%CupStats = out;
Cupname = input('What to name file: ', 's');
save(['CupStats_pool ' Cupname '.mat'],'CupStats','-v7.3');
disp('Saved');

 



%% Functions
function MPStats = getStainChannel(MPStats)
%check if all channel metas are the same
easy_mode = false;
if numel(unique([MPStats.NChannels])) == 1 & numel(unique([MPStats.MPchannel])) == 1
    easy_mode = true;
    NChannels  = MPStats(1).NChannels;
    MPchannel = MPStats(1).MPchannel;
end

if easy_mode
    channel_array = 1:NChannels;
    StainChannels = channel_array(channel_array~=MPchannel);
    for k = 1:length(MPStats)
        MPStats(k).StainChannels = StainChannels;
    end
else
    for k = 1:length(MPStats)
        channel_array = 1:MPStats(k).NChannels;
        StainChannels = channel_array(channel_array~=MPchannel);
    end
end

end

function centroid = get3DCentroid(binary3D)
    [y, x, z] = ndgrid(1:size(binary3D, 1), 1:size(binary3D, 2),1:size(binary3D, 3));
    centroid = round(mean([x(logical(binary3D)), y(logical(binary3D)),z(logical(binary3D)) ]));
end

function IMresized = resize3D(IM_original,MPStats)
%resize image so that one pixel = 0.1µm
realsize = size(IM_original).*[MPStats.PixelSizeXY MPStats.PixelSizeXY MPStats.PixelSizeZ];
IMresized = imresize3(IM_original,ceil(10*realsize));

end

function [edge_x,edge_y] = mask2outline(mask)
[mx,my] = meshgrid(1:size(mask,2),1:size(mask,1));
edge_mask = edge(mask);

edge_x = mx.*edge_mask;
edge_x = edge_x(:);
edge_x = edge_x(edge_x > 0);

edge_y = my.*edge_mask;
edge_y = edge_y(:);
edge_y = edge_y(edge_y > 0);



end


function [CupStats] = Cup_Tracing_GUI(MPStats)
num_I = length(MPStats);

for i = 1:num_I
    IM3D = imgaussfilt(resize3D(MPStats(i).IM3D,MPStats(i)),3);
    IMStain = resize3D(MPStats(i).IMStain,MPStats(i));
    h1 = sliceViewer(IM3D);
    center_manual = drawpoint();
    centroid_pixels = [round(center_manual.Position(2)),...
        round(center_manual.Position(1)), ...
        h1.SliceNumber];
    close
    
    centroid_mask = zeros(size(IM3D));
    centroid_mask(centroid_pixels(1)-20:centroid_pixels(1)+20,...
        centroid_pixels(2)-20:centroid_pixels(2)+20,...
        centroid_pixels(3)-20:centroid_pixels(3)+20) = 1;

    particle_mean = mean(IM3D(logical(centroid_mask)));
    background = prctile(IM3D,5,'all');

    threshold_intensity = (particle_mean+background)/4;
    

    XZslice_Stain = permute(IMStain(:,centroid_pixels(2),:),[1 3 2])';
    XZslice_Part = permute(IM3D(:,centroid_pixels(2),:),[1 3 2])';

   % imagesc(XZslice_Part)
   % axis equal
   % part_assisted = drawassisted();
    


    particle_mask = XZslice_Part > threshold_intensity;
    bwstats = regionprops("table",particle_mask,'all');
    partStats = bwstats(bwstats.Area == max(bwstats.Area),:);
    CupStats(i).partStats = partStats;
    [xp,yp] = mask2outline(particle_mask);
    particle_edges = [xp,yp];

   
    %imagesc(XZslice_Part)
    %particle_bound = drawcircle

    imagesc(XZslice_Stain)
    colormap gray
    clim([0 prctile(XZslice_Stain(:),99)/2]);
    axis equal
    hold on
    scatter(centroid_pixels(1),centroid_pixels(3),'r')
    %viscircles(partStats.Centroid,partStats.EquivDiameter/2)
    cup_edge = drawpolygon;
    cup_positions = cup_edge.Position;
    CupStats(i).cup_edge = cup_positions;
    close

    
    enclosed = inpolygon(particle_edges(:,1),particle_edges(:,2),cup_positions(:,1),cup_positions(:,2));
    CupStats(i).Fraction_Engulfed = sum(enclosed)/length(particle_edges);
    close;
    



end




end


