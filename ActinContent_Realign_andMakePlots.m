
%%
fprintf('Please select folder of interest containing MPRender files \n')
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

%% Main Loop - Realign

for f = 1:length(file_list)
    file_name = file_list{f};
    loadname = append(file_path,'/',file_name);
    disp(file_name)
    load(loadname);
    MPStats = RotateParticleGUI(MPStats);
    MPStats = MPStats([MPStats.Particle_Internalized]==0);

    numParticles = size(MPStats,1);

    figure('Position',[476 78 881 788],'Units','pixels')
    for i = 1:numParticles    
        C = MPStats(i).edgecoor_cart_aligned;
        Csph = MPStats(i).edgecoor_sph_aligned;
        actin = MPStats(i).stain_int/max(MPStats(i).stain_int);
        subplot(numParticles,3,3*i-2)
        trisurf(MPStats(i).TRI_Connectivity_aligned,C(:,1),C(:,2),C(:,3),...
            actin)
        colormap(hot);
        axis equal; view(3)
        axis off
        shading interp
        pbaspect([1 1 1])
        
        
        subplot(numParticles,3,3*i-1)
        %stereographic projection
        X2 = C(:,1)./(1.1*abs(min(C(:,3)))-(C(:,3)));
        Y2 = C(:,2)./(1.1*abs(min(C(:,3)))-(C(:,3)));
        newT = delaunay(X2,Y2);
        trisurf(newT,X2,Y2,C(:,3),actin);
        view(2)
        shading interp
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

    figname = strrep(file_name,'MPRender','PartialPlots');
    figname = strrep(figname,'.mat','.png');
    saveas(gcf,figname);
    close

    save(loadname,'MPStats','-v7.3');





end



%% functions

function NewStats = RotateParticleGUI(MPStats)
NewStats = MPStats;
nMPs = size(MPStats,1);

for i = 1:nMPs
    if isfield(MPStats,'edgecoor_cart_wcatorigin')
        C = MPStats(i).edgecoor_cart_wcatorigin;
        T = MPStats(i).TRI_Connectivity_wcatorigin;
        Csph = MPStats(i).edgecoor_sph_wcatorigin;
    elseif isfield(MPStats,'edgecoor_cart_aligned')
        C = MPStats(i).edgecoor_cart_aligned;
        T = MPStats(i).TRI_Connectivity_aligned;
        Csph = MPStats(i).edgecoor_sph_aligned;
    else
        C=MPStats(i).edgecoor_cart;
        T = MPStats(i).TRI_Connectivity;
        Csph = MPStats(i).edgecoor_sph;
    end
    stain = MPStats(i).stain_int;
    
    figure('Position',[476 78 881 788],'Units','pixels');
    trisurf(T,C(:,1),C(:,2),C(:,3),stain);
    colormap(hot);
    axis equal; view(3)
    axis off
    pbaspect([1 1 1])
    
    rotate3d(gca)
    Button1 = uicontrol('Parent',gcf,'Style','pushbutton','String',...
                    'Partial','Units','normalized','Position',[0.9 0.9 0.1 0.1],...
                    'Callback',@button_callback,...
                    'Visible','on');
    Button2 = uicontrol('Parent',gcf,'Style','togglebutton','String',...
                    'Finished','Units','normalized','Position',[0.9 0.7 0.1 0.1],...
                    'Callback',@button_callback,...
                    'Visible','on');
    uiwait(gcf)
    
    camera = campos;

    Particle_Internalized = false;
    if Button2.Value == 1
        Particle_Internalized = true;
    end

    NewStats(i).Particle_Internalized = Particle_Internalized;


    
    close()
    
    %THE PLAN
    % ROTATE TO THE BASE, CONVERT CAMERA COORDINATES TO THETA PHI R
    % camera = campos
    ThetaPhi  = cellfun(@(x) x(:,[1 2]),{Csph},'UniformOutput',false);
    [theta_base,phi_base,~] = cart2sph(camera(1),camera(2),camera(3));
    [ThetaRot,PhiRot] = Align_spheres_by_Rotation(ThetaPhi,double([theta_base phi_base+pi/2]));
    theta     = wrapToPi(ThetaRot{:}); 
    phi       = PhiRot{:};
    r         = Csph(:,3);
    [XN,YN,ZN] = sph2cart(theta,phi,r);

    NewStats(i).edgecoor_sph_aligned     = [theta,phi,r]      ;
    NewStats(i).TRI_Connectivity_aligned = delaunay(theta,phi);
    NewStats(i).edgecoor_cart_aligned = [XN,YN,ZN];
    
    % Also save the location of the cupbase
    [~,minloc] = min(pdist2([theta,phi],[.5*pi,0]));
    r_base = r(minloc);
    NewStats(i).CupBase = [theta_base phi_base r_base];

end



end


function button_callback(hObject,eventdata)
    if get(hObject,'Value') == 0
        %do nothing
    else
        uiresume;
        return
    end
end