
% Open UI to select the data files
w = warning('off', 'MATLAB:Java:DuplicateClass');
javaaddpath(fileparts(which('ParforProgressMonitor.class')));
warning(w);
clear('p','w');
% Open UI to select the data files
[data,~,FileName,PathName] = ReadBFImages('.tif');
% if READBFImages runs an error, try to clear the path and reset the path to the
% DaanParticleanalysis in the Github repo 

%% Extract the images and required metadata

if exist('OGdata','var'); data = OGdata;  end
[MPStats,data1                ] = Extract_Essential_Metadata(data,FileName,PathName,1);
[IM3D_MP,LLSMMask,zcorrfactor] = Extract_Images(data1,MPStats,MPStats(1).MPchannel);

[MPStats.IM3D                 ] = IM3D_MP{:};
[MPStats.LLSMMask             ] = LLSMMask{:};
[MPStats.PixelSizeZ_original  ] = MPStats.PixelSizeZ;
[MPStats.PixelSizeZ           ] = ArraytoCSL([MPStats.PixelSizeZ]/zcorrfactor);
[MPStats.zcorrFactor          ] = deal(zcorrfactor);

MPStats = orderfields(MPStats);
if ~all(size(data)==size(data1));     OGdata = data;     data = data1;       end        
clear('IM3D_MP','IM3DCell','LLSMMask','zcorrfactor','data1');


%% Threshold the images and identify particles

% Increasing the "UseIncreasedThreshold" value (between 0 and 1) excludes less particles that are
% close to/touching the border. Warning: this could result in errors later on. Using the watershed
% option increases computational time by a lot, but allows analyzing movies with adjacent particles.
Opts = {'UseIncreasedThreshold',0,'watershed',1};


MPStats = Threshold_images_and_identify_particles(MPStats,Opts);
clear('Opts');

%% Superlocalize particle edges and triangulate surface

% Ask the user about the use of sobel filtering and how much smoothing to apply to the image
edgedetectionsettings = inputdlg({'Use Sobel filter ("sobel") or derivative of line profiles ("direct")?',...
    'How much smoothing do you want to apply (in pixels)?',['Do you want to use stable mode? '...
    '(increases computational complexity and time, but can work better especially with adjacent particles)'],...
    'Desired (max) spacing between the points (in nm)?',['Do you want to use a regular spaced grid (reg) or '...
    'equidistant points (equi)?'],'Range in which is searched for the edge (in R)',...
    'Relative minimum peak intensity (0 - 100)'},'Edge Detection Settings',...
    [1 80],{'sobel','1','0','250','equi','0.25 - 0.75','99'});

% Apply sobel filtering (if desired)
usesobel = strcmpi(edgedetectionsettings{1},'sobel');
if usesobel
    XYZedges = Apply_3DSobel_filter({MPStats.IM3D},str2double(edgedetectionsettings{2}));
    [MPStats.IMedges] = XYZedges{:};
end

dashloc = strfind(edgedetectionsettings{6},'-');
radialbounds = [str2double(edgedetectionsettings{6}(1:(dashloc-1)))...
     str2double(edgedetectionsettings{6}((dashloc+1):end))];

[MPStats,Residuals_Problems_excluded] = Superlocalize_edges_using_gaussian_fitting(MPStats,...
    str2double(edgedetectionsettings{4})/1000,edgedetectionsettings{5},'DirectDerivative',~usesobel,...
    'usestablemode',str2double(edgedetectionsettings{3}),'smooth',str2double(edgedetectionsettings{2}),...
    'RadialBounds',radialbounds,'RelMinPeakSize',edgedetectionsettings{7});

%% Triangulate surface and determine particle statistics
MPStats = Triangulate_surface_and_determine_particle_statistics(MPStats);

clear('XYZedges','edgedetectionsettings','usesobel','dashloc','radialbounds')

%% Determine particle coverage by a secondary signal

if exist('data','var')
    Stain_channel = Find_Stain_Channel(data(1),MPStats);
    MPStats = Analyze_Secondary_Signal(data(:,1),MPStats,[],Stain_channel,'stain');
else
    stainname = select_stain(MPStats);
    MPStats = Analyze_Secondary_Signal([],MPStats,[],[],stainname);
end

clear('Stain_channel')

%% Convert secondary signal to mask and align cups

% Choose to use the maximum intensity or integrated intensity. To choose, you can plot both by running this line:
% figure; subplot(2,1,1); imagesc(max(MPStats(1).IMstain_radial,[],3)'); axis equal; axis off; subplot(2,1,2); imagesc(sum(MPStats(1).IMstain_radial,3)'); axis equal; axis off;
% The upper one is max intensity, lower integrated intensity
userinput = inputdlg('Use maximum intensity (max) or integrated (int) intensity signal?',...
            'Stain analysis options',[1 70],{'int'});
use_integrated_intensity = strcmp(userinput,'int');
stain_indicates_contact  = 1;

MPStats = Convert_secondary_signal_to_mask(MPStats,stain_indicates_contact,'use_integrated_intensity',use_integrated_intensity,'use_global_threshold',0);
MPStats = Determine_base_position_and_align(MPStats,'BaseLat',-pi/2,'BaseColongitude',0);

clear('use_integrated_intensity','stain_indicates_contact')

%% Optionally get cd18 stain

if exist('data','var')
    Stain_channel = Find_Stain_Channel(data(1),MPStats);
    MPStats = Analyze_Secondary_Signal(data(:,1),MPStats,[],Stain_channel,'cd18');
else
    stainname = select_stain(MPStats);
    MPStats = Analyze_Secondary_Signal([],MPStats,[],[],stainname);
end

clear('Stain_channel')


%%
fieldsToRemove = {'IM3D','IMcd18','IMcd18_bgcorr','IMedges','IMlm',...
    'IMstain','IMstain_bgcorr','IMstain_reg'};

for i = 1:length(fieldsToRemove)
    if isfield(MPStats,fieldsToRemove{i})
        MPStats = rmfield(MPStats,fieldsToRemove{i});
    end
end


Cupname = input('What to name file: ', 's');
save(['MPRender_pool ' Cupname '.mat'],'MPStats','-v7.3');
disp('Saved');




%% Loop through MPStats to create actin profiles for inspection

numParticles = size(MPStats,1);

figure('Position',[476 78 881 788],'Units','pixels')
for i = 1:numParticles    
    C = MPStats(i).edgecoor_cart_aligned;
    Csph = MPStats(i).edgecoor_sph_aligned;
    actin = MPStats(i).stain_int/max(MPStats(i).stain_int);
    subplot(numParticles,3,3*i-2)
    scatter3(C(:,1),C(:,2),C(:,3),30,MPStats(i).isincontact,'filled')
    colormap(hot);
    axis equal; view(3)
    axis off
    pbaspect([1 1 1])
    
    
    subplot(numParticles,3,3*i-1)
    mid_slice = mean(C(:,3));
    scatter(C(C(:,3)<mid_slice,1),C(C(:,3)<mid_slice,2),...
        25,actin(C(:,3)<mid_slice),'filled')
    axis equal
    axis off

    
    subplot(numParticles,3,3*i)
    [Csorted,I] = sort(Csph(:,2));
    Csorted = Csph(I,:);
    actinsorted = actin(I);
    meanActinLine = movmean(actinsorted,500);
    plot(Csorted(:,2),meanActinLine)
    xline(prctile(Csph(:,2),99))
    if isfield(MPStats(i),'cd18_int')
        cd18 = MPStats(i).cd18_int/max(MPStats(i).cd18_int);
        cd18sorted = cd18(I);
        meanCD18Line = movmean(cd18sorted,500);
        hold on
        plot(Csorted(:,2),meanCD18Line)
        legend({'Actin','CD18'})
    else
        legend('Actin')
    end







end








%%
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

function newdata = addEmptySlices(data)
%Add some buffer space
for i = 1:size(data,1)
    
     

end


end