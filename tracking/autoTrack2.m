function [trackDat] = autoTrack(trackDat,expmt,gui_handles)

%% Parse fields

    out_fields = trackDat.fields;
    in_fields = trackDat.fields;
    
    % temporarily remove fields not recognized by regionprops
    prop_fields = {'area';'BoundingBox';'centroid';'Convexarea';'ConvexHull';...
        'ConvexImage';'Eccentricity';'EquivDiameter';'EulerNumber';'Extent';...
        'Extrema';'Filledarea';'FilledImage';'Image';'majorAxisLength';...
        'minorAxisLength';'orientation';'Perimeter';'pixelIdxList';'PixelList';...
        'Solidity';'SubarrayIdx';'weightedCentroid'};
    remove = ~ismember(in_fields,prop_fields);
    in_fields(remove) = [];
    
    % add centroid and area to the input regionprops fields if not provided
    if ~any(strcmpi('centroid',in_fields)) && ...
            ~any(strcmpi('weightedCentroid',in_fields))
        in_fields = [in_fields; {'centroid'}];
    end
    if ~any(strcmpi('area',in_fields))
        in_fields = [in_fields; {'area'}];
    end
    if ~any(strcmpi('PixelList',in_fields))
        in_fields = [in_fields; {'PixelList'}];
    end
    
    % add BoundingBox as a field if dilate/erode mode
    if isfield(expmt.parameters,'dilate_element')
        in_fields = [in_fields; {'BoundingBox'}];
    end
    
%% Track objects

    trackDat.ct = trackDat.ct + 1;
    trackDat.in_fields = in_fields;

    % calculate difference image and current for vignetting
    switch trackDat.ref.bg_mode
        case 'light'
            diffim = (trackDat.ref.im - expmt.meta.vignette.im) -...
                        (trackDat.im - expmt.meta.vignette.im);
        case 'dark'
            diffim = (trackDat.im - expmt.meta.vignette.im) -...
                        (trackDat.ref.im - expmt.meta.vignette.im);
    end
    
    
    % get current image threshold and use it to extract region properties     
    im_thresh = get(gui_handles.track_thresh_slider,'value');
    
    % threshold image
    thresh_im = diffim > im_thresh;
    if isfield(expmt.meta.roi,'mask')
        thresh_im = thresh_im & expmt.meta.roi.mask;
    end
    
    % check image noise and dump frame if noise is too high
    record = true;
    if isfield(trackDat,'px_dist')
        idx = mod(trackDat.ct,length(trackDat.px_dist))+1;
        trackDat.px_dist(idx) = sum(thresh_im(:));
        trackDat.px_dev(idx) = ((nanmean(trackDat.px_dist) - ...
                expmt.meta.noise.mean)/expmt.meta.noise.std);
        
        if trackDat.px_dev(idx) > 7
            record = false;
        end
    end
        
    if record  
        
        if isfield(expmt.parameters,'dilate_sz') &&...
                expmt.parameters.dilate_sz > 0
            
            if ~isfield(expmt.parameters,'dilate_element') ||...
                    isempty(expmt.parameters.dilate_element)
                expmt.parameters.dilate_element = ...
                    strel('disk',expmt.parameters.dilate_sz);
            end
            
            % dilate and erode with same element to connect components
            dim = imdilate(thresh_im,expmt.parameters.dilate_element);
            eim = imerode(dim,expmt.parameters.dilate_element);
            thresh_im = eim;            
            
            clearvars dim eim mim
            
        end
            
        % get region properties
        props=regionprops(thresh_im,trackDat.im, in_fields);
        trackDat.thresh_im = thresh_im;

        % threshold blobs by area
        above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
            expmt.parameters.area_min;
        below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
            expmt.parameters.area_max;
        props(~(above_min & below_max)) = [];
        


        switch expmt.meta.track_mode
            case 'multitrack'
                [trackDat, expmt, props] = multiTrack(props, trackDat, expmt);
                trackDat.centroid = cat(1,trackDat.traces.cen);
                update = cat(1,trackDat.traces.updated);
                permutation = cat(2,trackDat.permutation{:})';

       
            case 'single'
                raw_cen = reshape([props.Centroid],2,length([props.Centroid])/2)';
                % Match centroids to last known centroid positions
                [permutation,update,raw_cen] = sortCentroids(raw_cen,trackDat,expmt);

                % Apply speed threshold to centroid tracking
                speed = NaN(size(update));

                if any(update)

                    % calculate distance and convert from pix to mm
                    d = sqrt((raw_cen(permutation,1)-trackDat.centroid(update,1)).^2 ...
                             + (raw_cen(permutation,2)-trackDat.centroid(update,2)).^2);
                    d = d .* expmt.parameters.mm_per_pix;

                    % time elapsed since each centroid was last updated
                    dt = trackDat.t - trackDat.tStamp(update);

                    % calculate speed and exclude centroids over speed threshold
                    tmp_spd = d./dt;
                    above_spd_thresh = tmp_spd > expmt.parameters.speed_thresh;
                    permutation(above_spd_thresh)=[];
                    update(update) = ~above_spd_thresh;
                    speed(update) = tmp_spd(~above_spd_thresh);

                end

                % Use permutation vector to sort raw centroid data and update
                % vector to specify which centroids are reliable and should be updated
                trackDat.centroid(update,:) = single(raw_cen(permutation,:));
                trackDat.tStamp(update) = trackDat.t;
                if isfield(props,'WeightedCentroid')
                    raw_cen = reshape([props.WeightedCentroid],2,...
                        length([props.WeightedCentroid])/2)';
                    trackDat.weightedCentroid(update,:) = ...
                        single(raw_cen(permutation,:));
                end

                % update centroid drop count for objects not updated this frame
                if isfield(trackDat,'drop_ct')
                    trackDat.drop_ct(~update) = trackDat.drop_ct(~update) + 1;
                end

                trackDat.update = update;
        end
    
    else
        
        % increment drop count for all objects if entire frame is dropped
        trackDat.drop_ct = trackDat.drop_ct + 1;
        
    end
    
%% Assign outputs

% assign any optional sorted output fields to the trackDat
% structure if listed in expmt.meta.fields. 
% return NaNs if record = false

if any(strcmpi('speed',out_fields))
    if record
        if exist('speed','var')
            trackDat.speed = single(speed);
        else
            trackDat.speed = cat(1,trackDat.traces.speed);
        end
    else
        trackDat.speed = single(NaN(size(trackDat.centroid,1),1)); 
    end
end

if any(strcmpi('area',out_fields))
    area = NaN(size(trackDat.centroid,1),1);
    if record
        area(update) = [props(permutation).Area];
    end
    trackDat.area = single(area .* (expmt.parameters.mm_per_pix^2));
end

if any(strcmpi('Orientation',out_fields))
    orientation = NaN(size(trackDat.centroid,1),1);
    if record
        orientation(update) = [props(permutation).Orientation];
    end
    trackDat.orientation = single(orientation);
end

if any(strcmpi('PixelIdxList',out_fields))
    pxList = cell(size(trackDat.centroid,1),1);
    if record
        pxList(update) = {props(permutation).PixelIdxList};
    end
    trackDat.pixelIdxList = (pxList);
end

if any(strcmpi('majorAxisLength',out_fields))
    maLength = NaN(size(trackDat.centroid,1),1);
    if record
        maLength(update) =[props(permutation).MajorAxisLength];
    end
    trackDat.majorAxisLength = single(maLength);
end

if any(strcmpi('minorAxisLength',out_fields))
    miLength = NaN(size(trackDat.centroid,1),1);
    if record
        miLength(update) =[props(permutation).MinorAxisLength];
    end
    trackDat.minorAxisLength = single(miLength);
end

if any(strcmpi('time',out_fields))
    trackDat.time = single(trackDat.ifi);
end

if any(strcmpi('VideoData',out_fields))
    trackDat.VideoData = trackDat.im;
end

if any(strcmpi('VideoIndex',out_fields))
    trackDat.VideoIndex = trackDat.ct;
end





            