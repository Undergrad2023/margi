function expmt = modelLensDistortion(expmt)


%% filter activity bouts
%{
% filter data for movement bouts
filt = expmt.Speed.data>0.1;
s = expmt.Speed.data(filt);


% intialize cam center coords for distance calculation
cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2]; 
cam_dist = squeeze(sqrt((expmt.Centroid.data(:,1,:)-cc(1)).^2 +...
    (expmt.Centroid.data(:,2,:)-cc(2)).^2));
d = cam_dist(filt);

spd_table = table(d(:),s(:),'VariableNames',{'Center_Distance';'Speed'});
lm = fitlm(spd_table,'Speed~Center_Distance');
if (lm.Coefficients{2,4})<0.05
    adat = expmt.Speed.data - lm.Coefficients{2,1}.*cam_dist;
    avg = nanmean(adat)';
    [r,p]=corrcoef([adat(:),cam_dist(:)],'rows','pairwise');
    disp(r(1,2));
    [r,p]=corrcoef([avg,expmt.ROI.cam_dist],'rows','pairwise');
    disp(r(1,2));
end



%% filter inactive individuals

% filter data for movement bouts
filt = nanmean(expmt.Speed.data)>0.1;

s = expmt.Speed.data(:,filt);


% intialize cam center coords for distance calculation
cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2]; 
cam_dist = squeeze(sqrt((expmt.Centroid.data(:,1,:)-cc(1)).^2 +...
    (expmt.Centroid.data(:,2,:)-cc(2)).^2));
d = cam_dist(:,filt);


spd_table = table(d(:),s(:),'VariableNames',{'Center_Distance';'Speed'});
lm = fitlm(spd_table,'Speed~Center_Distance');

if (lm.Coefficients{2,4})<0.05
    adat = expmt.Speed.data - lm.Coefficients{2,1}.*cam_dist;
    avg = nanmean(adat)';
    [r,p]=corrcoef([adat(:),cam_dist(:)],'rows','pairwise');
    disp(r(1,2));
    [r,p]=corrcoef([avg,expmt.ROI.cam_dist],'rows','pairwise');
    disp(r(1,2));
end
%}
%% filter nothing


s = expmt.Speed.data;

% intialize cam center coords for distance calculation
cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2]; 
cam_dist = squeeze(sqrt((expmt.Centroid.data(:,1,:)-cc(1)).^2 +...
    (expmt.Centroid.data(:,2,:)-cc(2)).^2));
d = cam_dist;

spd_table = table(d(:),s(:),'VariableNames',{'Center_Distance';'Speed'});
lm = fitlm(spd_table,'Speed~Center_Distance');

if (lm.Coefficients{2,4})<0.05
    adat = expmt.Speed.data - lm.Coefficients{2,1}.*cam_dist;
    avg = nanmean(adat)';
    [r,p]=corrcoef([adat(:),cam_dist(:)],'rows','pairwise');
    disp(r(1,2));
    [r,p]=corrcoef([avg,expmt.ROI.cam_dist],'rows','pairwise');
    disp(r(1,2));
end


%{
%% filter nothing, erase NaNs

s = expmt.Speed.data;
s(isnan(s))=0;

% intialize cam center coords for distance calculation
cc = [size(expmt.ref,2)/2 size(expmt.ref,1)/2]; 
cam_dist = squeeze(sqrt((expmt.Centroid.data(:,1,:)-cc(1)).^2 +...
    (expmt.Centroid.data(:,2,:)-cc(2)).^2));
d = cam_dist;

spd_table = table(d(:),s(:),'VariableNames',{'Center_Distance';'Speed'});
lm = fitlm(spd_table,'Speed~Center_Distance');
if (lm.Coefficients{2,4})<0.05
    adat = expmt.Speed.data - lm.Coefficients{2,1}.*cam_dist;
    avg = nanmean(adat)';
    [r,p]=corrcoef([adat(:),cam_dist(:)],'rows','pairwise');
    disp(r(1,2));
    [r,p]=corrcoef([avg,expmt.ROI.cam_dist],'rows','pairwise');
    disp(r(1,2));
end

disp('stop')
%}






