%%
fprintf('Please select folder of interest containing mprender files \n')
file_path = uigetdir('Select Folder of interest');

current_dir = pwd;
cd(file_path);
files = dir(file_path);

file_list = {};

for file = files'
    if contains(file.name,'.mat')
        file_list = [file_list file.name];
    end
end

%%
bigT = table();
for j = 1:length(file_list)
    load(file_list{j})
    out_array = zeros(200,2*length(MPStats));
    clearance_ratios = zeros(length(MPStats),2);
    names = cell(length(MPStats),1);

    for i = 1:length(MPStats)
        % Stereographic projection
        C = MPStats(i).edgecoor_cart_aligned;
        actin = MPStats(i).stain_int;
        names{i} = MPStats(i).FileName;
        
        X2 = C(:,1)./(1.1*abs(max(C(:,3)))-(C(:,3)));
        Y2 = C(:,2)./(1.1*abs(max(C(:,3)))-(C(:,3)));
        [z out] = rmoutliers([X2,Y2]);
        actin=actin(~out);
        newT = delaunay(z);
    
        x_grid = linspace(min(z(:,1)),max(z(:,1)),200);
        y_grid = linspace(min(z(:,2)),max(z(:,2)),200);
        [Xq,Yq]=meshgrid(x_grid,y_grid);
        gridded_data= griddata(z(:,1),z(:,2),actin,Xq,Yq);
        
        line_profilex = mean(gridded_data(:,95:105),2);
        line_profiley = mean(gridded_data(95:105,:)',2);
        out_array(:,2*i-1) = line_profilex;
        out_array(:,2*i) = line_profiley;
        
        plot(line_profilex);
        hold on
        point1 = drawpoint();
        point2 = drawpoint();
        left_bound = floor(point1.Position(1));
        right_bound = floor(point2.Position(1));
    
        full_contact = left_bound:right_bound;
        outer25_length = floor(0.25*length(full_contact));
    
        boundary = line_profilex([left_bound:left_bound+outer25_length,right_bound-outer25_length:right_bound]);
        interior = line_profilex(left_bound+outer25_length+1:right_bound-outer25_length-1);
    
        clearance_ratios(i,1) = mean(interior)/mean(boundary); 
        close
    
        plot(line_profiley);
        hold on
        point1 = drawpoint();
        point2 = drawpoint();
        left_bound = floor(point1.Position(1));
        right_bound = floor(point2.Position(1));
    
        full_contact = left_bound:right_bound;
        outer25_length = floor(0.25*length(full_contact));
    
        boundary = line_profiley([left_bound:left_bound+outer25_length,right_bound-outer25_length:right_bound]);
        interior = line_profiley(left_bound+outer25_length+1:right_bound-outer25_length-1);
    
        clearance_ratios(i,2) = mean(interior)/mean(boundary); 
    
    
    
    
    
    
        close
    
    end

    T = table(names,clearance_ratios);
    bigT = [bigT;T];

    

end


%%
writetable(bigT,'Demo_ClearanceRatios.csv')