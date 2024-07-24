function structLine = processFrame_forActinCup(stack,fileinfo,t)
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
    if c_display == 1
        radiusRange = [10,100];

        [labeledImage,centers,radii] = labelParticles(cdata,radiusRange);

        structLine.(structFields(2,:)) = table(centers, radii,...
            'VariableNames',{'Center','Radius'});
        structLine.LabeledImage = labeledImage;
    end
    
    

end


redStats = regionprops(structLine.LabeledImage,structLine.Channel2,...
            'Area','Centroid','Circularity','EquivDiameter', ...
            'MeanIntensity','MaxIntensity','MinIntensity');
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



structLine.Stats = particleStats;
