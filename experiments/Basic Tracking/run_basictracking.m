function expmt = run_basictracking(expmt,gui_handles,varargin)
%
% This is a blank experimental template to serve as a framework for new
% custom experiments. The function takes the master experiment struct
% (expmt) and the handles to the gui (gui_handles) as inputs and outputs
% the data assigned to out. In this example, object centroid, pixel area,
% and the time of each frame are output to file.


% Initialization: Get handles and set default preferences
gui_notify(['executing ' mfilename '.m'], gui_handles.disp_note);

% get image handle
imh = findobj(gui_handles.axes_handle, '-depth', 3, 'Type', 'image');  

% raw data fields to save each frame (append names of custom fields to
% flag fields for writing to disk)
trackDat.fields = {'centroid'; 'time'};   

% initialize labels, files, and cam/video
[trackDat, expmt] = autoInitialize(trackDat, expmt, gui_handles);

% lastFrame = false until last frame of the last video file is reached
trackDat.lastFrame = false;

% --------------------------------- %
% insert custom initialization here %
% --------------------------------- %


% Tracking Loop - Run until duration is exceeded or last frame is reached
while ~trackDat.lastFrame
    
    % update time stamps and frame rate
    [trackDat] = autoTime(trackDat, expmt, gui_handles);

    % query next frame and optionally correct lens distortion
    [trackDat,expmt] = autoFrame(trackDat, expmt,gui_handles);

    % track, sort to ROIs, evaluate noise level, output optional fields
    trackDat = autoTrack(trackDat, expmt, gui_handles);
    
    % --------------------------- %
    % insert custom routines here %
    % --------------------------- %

    % output data tracked fields to binary files
    [trackDat,expmt] = autoWriteData(trackDat, expmt, gui_handles);

    % update ref at the reference frequency or reset if noise thresh is exceeded
    %[trackDat, expmt] = autoReference(trackDat, expmt, gui_handles);  

    % update current image and display object positions 
    [trackDat, expmt] = autoDisplay(trackDat, expmt, imh, gui_handles);
    
    
end

