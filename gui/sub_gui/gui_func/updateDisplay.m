function updateDisplay(trackDat, expmt, im_handle, gui_handles)

% query the active display mode
active_disp = gui_handles.display_menu.UserData;

switch active_disp

    % raw image
    case 1         
        im_handle.CData = trackDat.im;
        if strcmp(im_handle.CDataMapping,'direct')
            im_handle.CDataMapping = 'scaled';
        end

    % difference image
    case 2
        if isfield(expmt,'ref') && isfield(expmt.vignette,'im')
        im_handle.CData = ...
            (trackDat.ref.im-expmt.vignette.im)-(trackDat.im-expmt.vignette.im);
            if strcmp(im_handle.CDataMapping,'scaled')
                im_handle.CDataMapping = 'direct';
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(4).Checked= 'off';
            gui_handles.display_menu.Children(4).Enable = 'off';
        end

    % threshold image
    case 3 
        if isfield(trackDat,'thresh_im')
            im_handle.CData = trackDat.thresh_im;
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(3).Checked= 'off';
            gui_handles.display_menu.Children(3).Enable = 'off';
        end

    % reference image
    case 4
        if isfield(expmt,'ref')
            im_handle.CData = trackDat.ref.im;
            if strcmp(im_handle.CDataMapping,'direct')
                im_handle.CDataMapping = 'scaled';
            end
        else
            gui_handles.display_menu.UserData = 1;
            gui_handles.display_menu.Children(5).Checked= 'on';
            gui_handles.display_menu.Children(2).Checked= 'off';
            gui_handles.display_menu.Children(2).Enable = 'off';
        end
end


if isfield(gui_handles.gui_fig.UserData,'cenText') && ...
        ishghandle(gui_handles.gui_fig.UserData.cenText(1)) &&...
        strcmp(gui_handles.gui_fig.UserData.cenText(1).Visible,'on')
    
    arrayfun(@updateText,gui_handles.gui_fig.UserData.cenText,...
        num2cell(trackDat.Centroid,2));
end


function updateText(h,pos)

h.Position = pos{:};



