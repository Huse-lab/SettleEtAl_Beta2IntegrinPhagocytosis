function structLine = processFrame_forTracking(stack,fileinfo,t)
% FUNCTION to process a given frame and create a new line in frameStruct
% update 9/28/22 to allow for blue channel if num_channels = 4; So far,
% this just allows 4 channels, blue, green, red, brightfield. or 
% 3 channels: green, red, brightfield
structLine = struct();


time_indx = [fileinfo.sBlockList_P0.TStart]==t;
num_channels = max([fileinfo.sBlockList_P0.CStart])+1;
num_frames = max([fileinfo.sBlockList_P0.TStart])+1;


framedata = stack(time_indx,1);
frameinfo = ...
    fileinfo.sBlockList_P0(time_indx);
for c = 0:num_channels-1        % loop through each channel
    
    c_indx = [frameinfo.CStart]==c;
    cdata = framedata{c_indx};
    c_display = 4 - num_channels+c;  % this adjusts the output labels to be uniform whether there are 4 channels or 3
    
    structLine.xDim =  size(cdata,1);
    structLine.yDim =  size(cdata,2);
    
    structFields = ['Channel' num2str(c_display); 'Circles' num2str(c_display)];
    structLine.(structFields(1,:)) = cdata;
    if c_display == 2
        radiusRange = [7,40];

        [labeledImage,centers,radii] = labelParticles(cdata,radiusRange);

        structLine.(structFields(2,:)) = table(centers, radii,...
            'VariableNames',{'Center','Radius'});
        structLine.LabeledImage = labeledImage;
    end
    
    

end


redStats = regionprops(structLine.LabeledImage,structLine.Channel2,...
            'Area','Centroid','Circularity','EquivDiameter', ...
            'MeanIntensity','MaxIntensity','MinIntensity','BoundingBox');
redStats = redStats(~isnan([redStats.MeanIntensity]));

greenStats = regionprops(structLine.LabeledImage,structLine.Channel1, ... 
    'MeanIntensity','MaxIntensity','MinIntensity');

greenStats = greenStats(~isnan([greenStats.MeanIntensity]));

particleStats = table([redStats.Area]', vertcat(redStats.Centroid),...
    [redStats.Circularity]',[redStats.EquivDiameter]',...
    [redStats.MeanIntensity]',[redStats.MaxIntensity]',...
    [redStats.MinIntensity]',[greenStats.MeanIntensity]',...
    [greenStats.MaxIntensity]',[greenStats.MinIntensity]','VariableNames',...
    {'Area','Centroid','Circularity','EquivDiameter','Red_MeanInt',...
    'Red_MaxInt','Red_MinInt','Green_MeanInt','Green_MaxInt','Green_MinInt'});

if num_channels == 4
    smoothed = imgaussfilt(structLine.Channel0,2);
    binary = imbinarize(smoothed,'adaptive');
    stats = regionprops(binary);
    numcells = sum([stats.Area] > 45 & [stats.Area] < 500);
    structLine.Num_Cells = numcells;
end

% get brightfield snaps for tracking/zernike analysis
Snaps = cell(height(particleStats),1);
for k = 1:height(particleStats)
    radius = particleStats.EquivDiameter(k)/2;
    center = particleStats.Centroid(k,:);
    
    hor_span = floor(center(2)-1.2*radius):ceil(center(2)+1.2*radius);
    hor_span(hor_span<1) = []; hor_span(hor_span > structLine.yDim) = []; % deal with the borders

    vert_span = floor(center(1)-1.2*radius):ceil(center(1)+1.2*radius);
    vert_span(vert_span<1) = []; vert_span(vert_span > structLine.yDim) = []; % deal with the borders
    brightfield_image = structLine.Channel3(hor_span,vert_span);

    %regularize the brightfields for downstream processing
    sz = size(brightfield_image);
    [Xo,Yo] = meshgrid(1:sz(2),1:sz(1));
    [Xq,Yq] = meshgrid(linspace(1,sz(2),25),linspace(1,sz(1),25));
    Snaps{k,1} = interp2(Xo,Yo,double(brightfield_image),Xq,Yq);
    

end

particleStats.Snaps = Snaps;


structLine.Stats = particleStats;
