function [varargout]=matchCentroids2ROIs(raw_cen,trackDat,expmt,gui_handles)

%   SORT CENTROID COORDINATES BASED ON DISTANCE TO KNOWN REFERENCE COORDINATES
%   This function sorts centroid coordinates based on the pairwise distance to one or two 
%   sets of reference coordinates and outputs a permutation vector for
%   sorting the input centroids.
%
%   MODES: Single Sort, Double Sort
%
%           Single Sort - [P,U] = matchCentroids2ROIs(CEN,C1)
%
%               Takes an Nx2 dimensional array of unsorted centroid 
%               coordinates (CEN) and an Mx2 array of reference coordinates
%               (C1) as inputs and finds the reference coordinate with the 
%               shortest distance to each unsorted centroid. The function 
%               outputs up to a permutation vector (P) that can be as large as 
%               Mx1 but will be Nx1 if N < M. This vector is a mapping of the 
%`              indices of CEN to their nearest neighbors in C1. If more
%               than one centroid is matched to the same reference
%               coordinate, the centroids are then restricted such that only 
%               the nearest neighbor of each reference coordinate will be
%               matched, thus ensuring that only one input centroid is
%               sorted to each reference centroid. In addition to the
%               permutation vector, an Mx1 logical update vector (U) is also 
%               output that is TRUE where a reference coordinate has been
%               matched to an unsorted centroid and false where no match
%               was found.
%
%           INPUTS
%
%               CEN - unsorted Nx2 centroid coordinates output from region 
%               props where N is the number of detected centroids
%
%               C1 - Mx2 reference coordinates where M is the expected
%               number of tracked objects. Works best if C1 is the last known
%               coordinates of a tracked object(s).
%
%           OUTPUTS
%
%               P - permutation vector that is Nx1 if N < M and Mx1 if
%               N >= M. For example: P = [2 5 1] specifies that the second
%               centroid in CEN is matched to the first coordinate of C1(U).
%               The fifth centroid of CEN is matched to the second
%               coordinate of C(U) etc. Indices 3 and 4 of CEN were not 
%               matched with any reference coordinate and are thus
%               excluded.
%
%               U - Mx1 logical update vector true where a reference
%               coordinate has been matched to an unsorted centroid. The
%               combination of P and U serves as a mapping between the
%               input centroids and the reference coordinates.
%
%                   eg. C(U,:) = CEN(P,:)
%
%           Double Sort - [P,U] = matchCentroids2ROIs(cen,C1,C2,thresh)
%
%               Double Sort has all the same core functionality of single
%               sort but undergoes an additional round of filtering using a
%               distance threshold to exclude unsorted centroids that are
%               too far from a known landmark (eg. the center of an ROI).
%
%           INPUTS
%                       
%               C2 - Mx2 reference coordinates where M is the expected
%               number of tracked objects. Works best if C2 are the
%               coordinates of known landmarks (eg. ROI coordinates).
%               Must be the same dimensions as C1. Paired coordinates
%               between C1 and C2 must be matched in order (eg. the index
%               of the last known position of an object must be matched to
%               the index of its the ROI position).
%
%               thresh - a scalar threshold value that serves as an upper
%               bound on the allowed distance from an unsorted centroid to
%               its matched coordinate in C2.
%

% get user data from gui
udat = gui_handles.gui_fig.UserData;

% Define placeholder data variables equal to number ROIs
tempCenDat=NaN(size(trackDat.Centroid,1),2);

% Initialize temporary centroid variables
tempCenDat(1:size(raw_cen,1),:)=raw_cen;

% Find nearest Last Known Centroid for each current centroid
% Replicate temp centroid data into dimensions compatible with dot product
% with the last known centroid of each fly
tD=repmat(tempCenDat,1,1,size(trackDat.Centroid,1));
c=repmat(trackDat.Centroid,1,1,size(tempCenDat,1));
c=permute(c,[3 2 1]);

% Use dot product to calculate pairwise distance between all coordinates
g=sqrt(dot((c-tD),(tD-c),2));
g=abs(g);

% Returns minimum distance to each previous centroid and the indces (j)
% Of the temp centroid with that distance
[~,j]=min(g);

% Initialize empty placeholders for permutation and inclusion vectors
sorting_permutation=[];
update_centroid = false(size(trackDat.Centroid,1),1);

    % For the centroids j, calculate speed and distance to ROI center for thresholding
    if size(raw_cen,1)>0 
        
        switch udat.sort_mode
            
          case 'distance'
                
            % Calculate distance to known landmark such as the ROI center
            secondary_distance=abs(sqrt(dot(raw_cen(j,:)'-expmt.ROI.centers',expmt.ROI.centers'-raw_cen(j,:)')))';

            % Exclude centroids that move too fast or are too far from the ROI center
            % corresponding to the previous centroid each item in j, was matched with
            mismatch = secondary_distance .* expmt.parameters.mm_per_pix > udat.distance_thresh;
            j(mismatch)=NaN;
            
            % If the same ROI is matched to more than one coordinate, find the nearest
            % one and exclude the others
            u=unique(j(~isnan(j)));                                         % Extract the unique values of the ROIs
            duplicateCen=u(squeeze(histc(j,u))>1);
            duplicateROIs=find(ismember(j,u(squeeze(histc(j,u))>1)));       % Find the indices of duplicate ROIs

            % Calculate pairwise distances between duplicate ROIs and temp centroids
            % using the same method above
            tD=repmat(tempCenDat(duplicateCen,:),1,1,size(trackDat.Centroid,1));
            c=repmat(trackDat.Centroid,1,1,size(tempCenDat(duplicateCen,:),1));
            c=permute(c,[3 2 1]);
            g=sqrt(dot((c-tD),(tD-c),2));
            g=abs(g);
            [~,k]=min(g,[],3);
            j(duplicateROIs)=NaN;
            j(k)=duplicateCen;

            % if unsorted centroids remain

            % Update last known centroid and orientations
            sorting_permutation = j(~isnan(j));
            sorting_permutation = squeeze(sorting_permutation);
            update_centroid=~isnan(j);
        
        
          case 'bounds'  
              
            switch udat.ROI_mode    
               case 'grid'
                 % find candidate ROIs for each centroid
                 ROI_num = arrayfun(@(x) ...
                     gridAssignROI(x,expmt.ROI.vec),num2cell(raw_cen,2),'UniformOutput',false);
               case 'auto'
                 ROI_num = arrayfun(@(x) ...
                     autoAssignROI(x,expmt.ROI.corners),num2cell(raw_cen,2),'UniformOutput',false);
            end


             
             % remove centroids out of bounds of any ROI
             filt = cellfun(@isempty,ROI_num);
             raw_cen(filt,:)=[];
             ROI_num(filt)=[];
             
             
             % check for centroids with more than one ROI assigned
             dupROIs = cellfun(@length,ROI_num)>1;
             if any(dupROIs)
                 
                 % find ROI with nearest last centroid to each raw_cen                
                 ROI_num(dupROIs) = cellfun(@(x,y) closestCentroid(x,y,trackDat.Centroid),...
                     num2cell(raw_cen(dupROIs,:),2),ROI_num(dupROIs),'UniformOutput',false);
                 
             end   
              
             % find ROIs with more than one centroid assignment
             ROI_num = cat(2,ROI_num{:});    
             hasDupCen = find(histc(ROI_num,1:length(expmt.ROI.row))>1);
             if ~isempty(hasDupCen)
                dupCenIdx = arrayfun(@(x) find(ismember(ROI_num,x)),...
                    hasDupCen,'UniformOutput',false);
                [~,discard] = cellfun(@(x,y) closestCentroid(x,y,raw_cen),...
                    num2cell(trackDat.Centroid(hasDupCen,:),2),dupCenIdx','UniformOutput',false);
                ROI_num(cat(2,discard{:}))=[];
                raw_cen((cat(2,discard{:})),:)=[];
             end
             
             % assign outputs for sorting data
             [~,sorting_permutation] = sort(ROI_num);
             update_centroid = ismember(1:length(expmt.ROI.row),ROI_num);
           
        end


    end
   
    
    for i=1:nargout
        switch i
            case 1, varargout(i) = {sorting_permutation};
            case 2, varargout(i) = {squeeze(update_centroid)};
            case 3, varargout(i) = {raw_cen};
        end
    end
        

end


function ROI_num = gridAssignROI(cen,gv)

    % get the bounds for each ROI at
    % current x and y position
    cen=cen{1};
    xL = cen(1) > gv(:,2,1).*cen(2) + gv(:,2,2);
    xR = cen(1) < gv(:,4,1).*cen(2) + gv(:,4,2);
    yT = cen(2) > gv(:,1,1).*cen(1) + gv(:,1,2);
    yB = cen(2) < gv(:,3,1).*cen(1) + gv(:,3,2);
    
    % identify matching ROI, if any
    in_bounds = xL & xR & yT & yB;
    ROI_num = find(in_bounds);       

end

function autoAssignROI(cen,b)

    % get the bounds for each ROI at
    % current x and y position
    cen=cen{1};
    xL = cen(1) > b(1);
    xR = cen(1) < b(3);
    yT = cen(2) > b(2);
    yB = cen(2) < b(4);
    
    % identify matching ROI, if any
    in_bounds = xL & xR & yT & yB;
    ROI_num = find(in_bounds);   


end


function [candidate_idx,no_match] = closestCentroid(target_cen,candidate_idx,candidate_cen)
    
% find the candidate centroid closest to the target centroid

% restrict the list of candidates to the indices in candidate idx
candidate_cen = candidate_cen(candidate_idx,:);

% find index for candidate with minimum distance to target
[~,j] = min(sqrt((target_cen(1)-candidate_cen(:,1)).^2 +...
    (target_cen(2)-candidate_cen(:,2)).^2));
no_match = candidate_idx(candidate_idx~=candidate_idx(j));
candidate_idx = candidate_idx(j);

end

