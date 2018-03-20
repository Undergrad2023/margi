function [varargout]=bootstrap_speed_blocks(expmt,blocks,nReps)

% Create bootstrapped distribution of occupancy from slow phototaxis data.
% For each bootstrap iteration:
%   1. Choose a fly at random
%   2. Then select a stimulus bout at random
%   3. Repeat the process until the sequence of bouts equals the duration
%      of the experiment.
%   4. Repeat steps 1-3 to create a bootstrapped score for each animal in
%      the experiment to create a distribution of scores to measure both 
%      mean and dispersion.
%   5. Repeat steps 1-4 nReps times to assess the likeliness of the data by
%      random chance.

%% bootstrap sample data

% restrict based on minimum activity
nf = expmt.nTracks;
active = expmt.Speed.avg>0.01;
speed = expmt.Speed.map.Data.raw(active,:);
blocks = blocks(active);
nBouts = cell2mat(cellfun(@size,blocks','UniformOutput',false));
nBouts = nBouts(:,1);
blocks(nBouts==0) = [];
nBouts(nBouts==0)=[];

% get bout lengths
bout_length = NaN(max(nBouts),nf);
for i = 1:length(blocks)
    tmp_idx = blocks{i};
    bout_length(1:nBouts(i),i) = tmp_idx(:,2) - tmp_idx(:,1) +1;
end


avg = nanmean(bout_length(:));      % mean bout length
target = expmt.nFrames*nf;             % target frame num
draw_sz = round(target/avg);

bs_speeds = NaN(nReps,nf);

% create waitbar object
h = waitbar(0,['iteration 0 out of ' num2str(nReps)]);
h.Name = 'Bootstrap resampling speed data';

%%
disp(['resampling data with ' num2str(nReps) ' replicates'])
disp('may a take a while with if number of replications is > 1000')
for j = 1:nReps
    
    % draw IDs
    ids = randi([1 length(blocks)],draw_sz,1);
    bouts = ceil(rand(size(ids)).*nBouts(ids));
    
    % get linear indices
    lin_ind = sub2ind(size(bout_length),bouts,ids);
    frame_num = sum(bout_length(lin_ind));
    
    while frame_num < target
        
        d = target-frame_num;
        sz = ceil(d/avg*1.2);
        
        % draw IDs
        tmp_ids = randi([1 length(blocks)],sz,1);
        tmp_bouts = ceil(rand(size(tmp_ids)).*nBouts(tmp_ids));
        
        new_ind = sub2ind(size(bout_length),tmp_bouts,tmp_ids);
        frame_num = frame_num + sum(bout_length(new_ind));
        
        ids = [ids;tmp_ids];
        bouts = [bouts;tmp_bouts];
        
        clearvars tmp_ids tmp_bouts
    end
    
    % create speed vector
    tmp_speed = single(NaN(frame_num,1));
    ct=0;
    for i=1:length(ids)
        k1=blocks{ids(i)}(bouts(i),1);
        k2=blocks{ids(i)}(bouts(i),2);
        tmp_speed(ct+1:ct+bout_length(bouts(i),ids(i)))=speed(ids(i),k1:k2);
        ct=ct+bout_length(bouts(i),ids(i));
    end
    
    tmp_speed(target+1:end)=[];
    tmp_speed = reshape(tmp_speed,target/nf,nf);
    bs_speeds(j,:) = nanmean(tmp_speed);
    
    if ishghandle(h)
        waitbar(j/nReps,h,['iteration ' num2str(j) ' out of ' num2str(nReps)]);
    end

    clearvars ids bouts tmp_speed lin_ind
    
end

if ishghandle(h)
    close(h);
end
    

%%

bs.obs = log(nanmean(expmt.Speed.map.Data.raw,2));
bs.include = active;
bs.sim = log(bs_speeds);

% create histogram of occupancy scores
binmin=min(bs.sim(:));
binmax=max(bs.sim(:));
w = binmax - binmin;
plt_res = w/(10^floor(log10(nf)));
bs.bins = binmin:plt_res:binmax;
c = histc(bs.sim,bs.bins) ./ repmat(sum(histc(bs.sim,bs.bins)),numel(bs.bins),1);
[bs.avg,~,bs.ci95,~] = normfit(c');

%% generate plots

f=figure();
hold on

range = [min([bs.sim(:);bs.obs(:)]) max([bs.sim(:);bs.obs(:)])];
range(1) = floor(range(1));
range(2) = ceil(range(2));

% plot bootstrapped trace
plot(bs.bins,bs.avg,'b','LineWidth',2);

datbins = linspace(min(bs.obs(:)),max(bs.obs(:)),length(bs.bins));
% plot observed data
c = histc(bs.obs,datbins) ./ sum(sum(histc(bs.obs,datbins)));
c = [0 c' 0];
datbins = [range(1) datbins range(2)];
plot(datbins,c,'r','LineWidth',2);
set(gca,'XLim',range,'YLim',[0 max(bs.avg)]);
legend({['bootstrapped (nReps = ' num2str(nReps) ')'];'observed'});
title(['speed histogram (obs v. bootstrapped)']);

% add confidence interval patch
vx = [bs.bins fliplr(bs.bins)];
vy = [bs.ci95(1,:) fliplr(bs.ci95(2,:))];
ph = patch(vx,vy,[0 0.9 0.9],'FaceAlpha',0.3);
uistack(ph,'bottom');

for i=1:nargout
    switch i
        case 1, varargout{i} = bs;
        case 2, varargout{i} = f;
    end
end







