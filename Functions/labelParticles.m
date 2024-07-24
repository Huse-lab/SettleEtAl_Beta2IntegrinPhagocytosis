function [labeledimage,centers,radii] = labelParticles(image,radiusRange)
% custom FUNCTION to label particles using imfindcircles and output a
% a label image, given a particle range of acceptable radii
xDim = size(image,1);
yDim = size(image,2);

[xx,yy] = meshgrid(1:xDim,1:yDim);
[centers, radii] = imfindcircles(image,radiusRange);

if ~isempty(centers)
    xfilter = ceil(centers(:,1)+radii*1.4) <= xDim & ...
        floor(centers(:,1)-radii*1.4) >= 0 ; 
    yfilter = ceil(centers(:,2)+radii*1.4) <= yDim & ...
        floor(centers(:,2)-radii*1.4) >= 0 ;
else
    xfilter = [];
    yfilter = [];
    end
centers = centers(xfilter & yfilter,:);
radii = radii(xfilter & yfilter);

num_circles = length(radii);

labeledimage = zeros([xDim,yDim]);
for i = 1:num_circles
    mask= sqrt((xx-centers(i,1)).^2+(yy-centers(i,2)).^2)<=radii(i);
    labeledimage(mask)=i;
end