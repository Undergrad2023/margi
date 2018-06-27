function trackDat = refRawCrossPatch(trackDat, expmt, gui_handles)
% patch bad areas of the reference with the raw image if possible


% compute inverse difference image and threshold to identify target patches
switch trackDat.ref.bg_mode
    case 'light'
        inv_diff = trackDat.im - trackDat.ref.im;     
    case 'dark'
        inv_diff = trackDat.ref.im - trackDat.im;
end

% threshold blobs by area
inv_thresh = inv_diff > gui_handles.track_thresh_slider.Value;
props = regionprops(inv_thresh,'Area','PixelIdxList');
above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
    gui_handles.gui_fig.UserData.area_min;
below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
    gui_handles.gui_fig.UserData.area_max;
props(~(above_min & below_max)) = [];

% update reference image with target patches from the raw image
pixList = cat(1,props.PixelIdxList);
trackDat.ref.im(pixList) = trackDat.im(pixList);

%{
% get per ROI background luminance
roi_ims = cellfun(@(b) trackDat.ref.im(b(2):b(4),b(1):b(3)), ...
             num2cell([floor(expmt.meta.roi.corners(:,[1 2]))...
             ceil(expmt.meta.roi.corners(:,[3 4]))],2),'UniformOutput',false);
roi_lum = cellfun(@(im) mean(im(:))*0.9, roi_ims);
switch trackDat.ref.bg_mode
    case 'light'
        roi_thresh = cellfun(@(im,lum) im(:)<lum, ...
            roi_ims, num2cell(roi_lum), 'UniformOutput',false);
    case 'dark'
        roi_thresh = cellfun(@(im,lum) im(:)>lum, ...
            roi_ims, num2cell(roi_lum), 'UniformOutput',false);
end

% find and filter target regions
vim_thresh = ~expmt.meta.roi.mask;
vim_thresh(cat(1,expmt.meta.roi.pixIdx{:})) = cat(1,roi_thresh{:});
props = regionprops(vim_thresh,'Area','PixelIdxList');
above_min = [props.Area]  .* (expmt.parameters.mm_per_pix^2) > ...
    gui_handles.gui_fig.UserData.area_min*2;
below_max = [props.Area] .* (expmt.parameters.mm_per_pix^2) <...
    gui_handles.gui_fig.UserData.area_max;
props(~(above_min & below_max)) = [];

% replace targets with background
pixList = cat(1,props.PixelIdxList);
gh = fspecial('gaussian',30,5);
filt_im = imfilter(expmt.meta.ref.im, gh);
trackDat.ref.im(pixList) = filt_im(pixList);
%}



