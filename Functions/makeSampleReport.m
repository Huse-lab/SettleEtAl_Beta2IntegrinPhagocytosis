function outStats = makeSampleReport(mat_path,plot_option)
% function to take a frameStruct object and make a set of plots to show
% results for this particular sample to help with debugging and
% demonstrating the analysis method
% adjusted version to be ok with MATLAB 2020b

matFile = load(mat_path);
frameStruct = matFile.frameStruct;
num_frames = length(frameStruct);
if plot_option == 1
    figure('Position',[560 39 1020 909],'Units','pixels')
    % Show image with Green/Red Ratios
    subplot(4,4,[1,2,5,6])
    t1_ratio = zeros(frameStruct(end).xDim,frameStruct(end).yDim);
    for i = 1:height(frameStruct(1).Stats )
        t1_ratio(frameStruct(1).LabeledImage==i) = frameStruct(1).Stats.Green_MeanInt(i)/frameStruct(1).Stats.Red_MeanInt(i);
    end
    imagesc(t1_ratio);colorbar; axis off; axis equal;
    title('t=0, FITC/LRB Ratio')
    colormap hot
    
    subplot(4,4,[3,4,7,8])
    tN_ratio = zeros(frameStruct(end).xDim,frameStruct(end).yDim);
    for i = 1:height(frameStruct(end).Stats)
        tN_ratio(frameStruct(end).LabeledImage==i) = frameStruct(end).Stats.Green_MeanInt(i)/frameStruct(end).Stats.Red_MeanInt(i);
    end
    imagesc(tN_ratio);colorbar; axis off; axis equal;
    title(['t=' num2str(frameStruct(end).TimeStamp/60) 'min, FITC/LRB Ratio'])
    
    % Plot distribution of green/red ratios
    subplot(4,4,9:10)
    ksdensity(frameStruct(1).Stats.Green_MeanInt./frameStruct(1).Stats.Red_MeanInt)
    hold on 
    ksdensity(frameStruct(end).Stats.Green_MeanInt./frameStruct(end).Stats.Red_MeanInt)
    legend({'t0','tFinal'})
    xlabel('FITC/LRB Ratio')
    ylabel('Frequency of Particles')
end
% Plot treshhold setting

allparticle_ratios = [];
for k = 1:length(frameStruct)
    if ~isempty(frameStruct(k).xDim)
        allparticle_ratios = [allparticle_ratios; frameStruct(k).Stats.Green_MeanInt./ ...
            frameStruct(k).Stats.Red_MeanInt];
    end
end
[pf xi] = ksdensity(allparticle_ratios);
[values,locs] = findpeaks(pf);
if length(values) == 2
    hi = xi(locs(2));
    lo = xi(locs(1));
else 
    %Get two highest peaks
    [top,top_idx] = max(values);
    values(top_idx) = 0;
    [second,second_idx] = max(values);
    if second < 0.1*top
        second = 0;
        second_idx = 1;
    end
    
    %figure out which is high and which is low
    hi = xi(locs(max(top_idx,second_idx)));
    lo = xi(locs(min(top_idx,second_idx)));
end
thresh = mean([lo,hi]);
if plot_option == 1
    subplot(4,4,11:12);
    plot(xi,pf)
    hold on
    
    xline(lo,'k')
    xline(hi,'k')
    
    xline(thresh,'r--','Threshold')
    xlabel('FITC/LRB Ratio')
    ylabel('Frequency of Particles')
    title('All Timepoints Combined')
end


% Calculate stats
NumParticles = zeros(num_frames,1);
NumAcidified = zeros(num_frames,1);
NumCells = zeros(num_frames,1);
PercentAcidified = zeros(num_frames,1);
TimeStamp = zeros(num_frames,1);
for k = 1:length(frameStruct)
    if ~isempty(frameStruct(k).xDim)
        NumParticles(k) = height(frameStruct(k).Stats);
        ratios = (frameStruct(k).Stats.Green_MeanInt./frameStruct(k).Stats.Red_MeanInt);
        NumAcidified(k) = length(ratios(ratios < thresh));
        NumCells(k) = frameStruct(k).Num_Cells;
        PercentAcidified(k) = NumAcidified(k)/NumParticles(k);
        TimeStamp(k) = frameStruct(k).TimeStamp;

    end
end

outStats = table(TimeStamp, PercentAcidified,NumParticles,NumAcidified,NumCells);

if plot_option == 1
    subplot(4,4,13:14)
    plot([frameStruct.TimeStamp]',outStats.PercentAcidified)
    ylim([0 1])
    xlabel('Time (s)')
    ylabel('Percent Acidified')
    
    subplot(4,4,15:16)
    plot([frameStruct.TimeStamp]',outStats.NumAcidified)
    xlabel('Time (s)')
    ylabel('# of Particles Acidified')
end