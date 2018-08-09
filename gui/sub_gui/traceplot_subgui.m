function varargout = traceplot_subgui(varargin)
% TRACEPLOT_SUBGUI MATLAB code for traceplot_subgui.fig
%      TRACEPLOT_SUBGUI, by itself, creates a new TRACEPLOT_SUBGUI or raises the existing
%      singleton*.
%
%      H = TRACEPLOT_SUBGUI returns the handle to a new TRACEPLOT_SUBGUI or the handle to
%      the existing singleton*.
%
%      TRACEPLOT_SUBGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACEPLOT_SUBGUI.M with the given input arguments.
%
%      TRACEPLOT_SUBGUI('Property','Value',...) creates a new TRACEPLOT_SUBGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before traceplot_subgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to traceplot_subgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help traceplot_subgui

% Last Modified by GUIDE v2.5 08-Aug-2018 18:17:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @traceplot_subgui_OpeningFcn, ...
                   'gui_OutputFcn',  @traceplot_subgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before traceplot_subgui is made visible.
function traceplot_subgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to traceplot_subgui (see VARARGIN)

% get expmt struct and generate vector mask
expmt = varargin{1};
detach(expmt);
attach(expmt.data.centroid);
handles.trace_fig.UserData.expmt = expmt;
[~,p] = memory;
mem = p.PhysicalMemory.Available;
n = mem/(8*expmt.meta.num_frames*2*6) * expmt.meta.num_frames * 0.1;
if expmt.meta.num_frames > n
    frame_rate = median(expmt.data.time.raw());
    handles.trace_fig.UserData.idx = 1:round(frame_rate):expmt.meta.num_frames;
    if numel(handles.trace_fig.UserData.idx) > n
        handles.trace_fig.UserData.idx = floor(linspace(1,expmt.meta.num_frames,n));
    end
else
    handles.trace_fig.UserData.idx = 1:expmt.meta.num_frames;
end

% disable extra controls if there are too few rois
max_roi = expmt.meta.num_traces;
all_ctls = findobj(handles.trace_fig,'-depth',1,'-property','Enable');
all_tags = get(all_ctls,'Tag');
ctl_nums = cellfun(@(s) regexp(s,'\d','match'),all_tags,'UniformOutput',false);
enable_ctl = cellfun(@(s) isempty(s) || str2num(s{1})<=max_roi, ctl_nums);
set(all_ctls(~enable_ctl),'Enable','off');

% initialize edit boxes
eb = findobj(handles.trace_fig,'-depth',1,'Style','edit');
[~,p] = sort(get(eb,'Tag'));
eb = eb(p);
for i=1:length(eb)
    if i <= expmt.meta.roi.n
        eb(i).String = num2str(i);
    end
end

% initialize slider bars
sb = findobj(handles.trace_fig,'-depth',1,'Style','slider');
[~,p] = sort(get(sb,'Tag'));
sb = sb(p);
for i=1:6
    sb(i).Min = 1;
    cap = expmt.meta.num_frames-20000;
    cap(cap<1)=expmt.meta.num_frames;
    stp = 10000/cap/10;
    stp(stp>1)=1;
    stp2 = stp*10;
    stp2(stp2>1) = 1;
    sb(i).Max = cap;
    if i <= expmt.meta.num_traces && ~strcmp(sb(i).Enable,'off')
        dispTrace(i,handles);
    end
    if stp == 1
        sb(i).SliderStep(2) = inf;
        sb(i).SliderStep(1) = 0.99;
        sb(i).Enable = 'off';
    else
        sb(i).SliderStep(2) = stp2;
        sb(i).SliderStep(1) = stp;
    end
end


% Choose default command line output for traceplot_subgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

uiwait(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = traceplot_subgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];


% --- Executes on slider movement.
function roi_num_slider_Callback(hObject, eventdata, handles)
% hObject    handle to roi_num_slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% query plot number
plot_num = str2double(hObject.Tag(end));

% update edit box display
hObject.Value = floor(hObject.Value);

% update plot
dispTrace(plot_num,handles);

guidata(hObject,handles);



% --- Executes during object creation, after setting all properties.
function roi_num_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roi_num_slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_ROI_num_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ROI_num1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% query plot and ROI numbers
plot_num = str2double(hObject.Tag(end));
hObject.Value = str2double(hObject.String);
handles.(['roi_num_slider' num2str(plot_num)]).Value = hObject.Value;

% update plot
dispTrace(hObject.Value,plot_num,handles);



% --- Executes during object creation, after setting all properties.
function edit_ROI_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ROI_num1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dispTrace(plot_num,handles)

% get associated handles
eb = handles.(['edit_ROI_num' num2str(plot_num)]);
sb = handles.(['roi_num_slider' num2str(plot_num)]);
ah = handles.(['pos_axes' num2str(plot_num)]);
th = handles.(['fr_label' num2str(plot_num)]);
lh = findobj(ah.Children,'Type','Line','-depth',1);
expmt = handles.trace_fig.UserData.expmt;

% retrieve current roi number and frame range
roi = str2double(eb.String);
ii = ceil(round(sb.Value/1000)*1000)+1;
if ii+9999 > expmt.meta.num_frames
    ii = ii:expmt.meta.num_frames;
else
    ii = ii:ii+9999;
end

if isempty(ii)
    return
end
x = expmt.data.centroid.raw(ii,1,roi);
y = expmt.data.centroid.raw(ii,2,roi);
th.String = sprintf('%i\t - \t%i',ii(1),ii(end));

% update position plot
if isempty(lh) || eb.UserData ~= roi
    ph=plot(ah,x(:),y(:),'k','LineWidth',0.5);
    axis(ah,'equal');
    reset(expmt.data.centroid);
    smpl_sz = 10000;
    smpl_sz(smpl_sz>expmt.meta.num_frames) = expmt.meta.num_frames;
    smpl = randperm(expmt.meta.num_frames,smpl_sz);
    smpl = expmt.data.centroid.raw(smpl,:,roi);
    reset(expmt.data.centroid);
    mu = nanmean(smpl);
    std = max(nanstd(smpl));
    if all(~isnan([mu std]))
        ah.XLim = mu(1) + (std*3).*[-1 1];
        ah.XTick = [ah.XLim(1) mean(ah.XLim) ah.XLim(2)];
        ah.XTickLabel = [-1 0 1];
        ah.YLim = mu(2) + (std*3).*[-1 1];
        ah.YTick = [ah.YLim(1) mean(ah.YLim) ah.YLim(2)];
        ah.YTickLabel = [-1 0 1];
        ylabel(ah,'Position','FontSize',12);
    end
else
    lh.XData = x;
    lh.YData = y;
end

% update speed plot
s = sqrt(diff(x).^2+diff(y).^2);
ah = handles.(['speed_axes' num2str(plot_num)]);
lh = findobj(ah.Children,'Type','Line','-depth',1);
if isempty(lh) || eb.UserData ~= roi
    ph=plot(ah,s(:),'k','LineWidth',0.75);
    ah.XTick = [];
    ah.XTickLabel = [];
    if max(s) > 0
        s = sqrt(sum(diff(smpl).^2,2));
        ah.YLim = [0 ceil(max(s))];
        ah.YTick = ah.YLim;
        ah.YTickLabel = ah.YLim;
    end
    ylabel(ah,'Spd','FontSize',12);
else
    lh.YData = s;
end
clear s x y

% update current roi number
eb.UserData = roi;



% --- Executes on button press in prev_pushbutton.
function prev_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to prev_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% query value of first plot
expmt = handles.trace_fig.UserData.expmt;
max_idx = expmt.meta.num_traces;
start = str2double(handles.edit_ROI_num1.String);
min_idx = 1;
if start < max_idx
   handles.next_pushbutton.Enable = 'on'; 
end
start = start-6;
if start <= min_idx
    start = start + (min_idx - start);
    hObject.Enable = 'off';
end

% get edit boxes
eb = findobj(handles.trace_fig,'-depth',1,'Style','edit');
[~,p] = sort(get(eb,'Tag'));
eb = eb(p);
sb = findobj(handles.trace_fig,'-depth',1,'Style','slider');
[~,p] = sort(get(sb,'Tag'));
sb = sb(p);
for i=1:length(eb)
    if ~strcmp(eb(i).Enable,'off')
        eb(i).String = num2str(start+i-1);
        sb(i).Value = 1;
    end
end

for i = 1:6
    if start <= max_idx
        dispTrace(i,handles);
    end
end


% --- Executes on button press in next_pushbutton.
function next_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to next_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB

% query value of virst plot
start = str2double(handles.edit_ROI_num1.String);
expmt = handles.trace_fig.UserData.expmt;
max_idx = expmt.meta.num_traces;
start = start+6;
if start + 5 >= max_idx
    start = start - (start + 5 - max_idx);
    hObject.Enable = 'off';
end
if start > 1
    handles.prev_pushbutton.Enable = 'on';
end

% get edit boxes
eb = findobj(handles.trace_fig,'-depth',1,'Style','edit');
[~,p] = sort(get(eb,'Tag'));
eb = eb(p);
sb = findobj(handles.trace_fig,'-depth',1,'Style','slider');
[~,p] = sort(get(sb,'Tag'));
sb = sb(p);
for i=1:length(eb)
    if ~strcmp(eb(i).Enable,'off')
        eb(i).String = num2str(start+i-1);
        sb(i).Value = 1;
    end
end

for i = 1:6
    if start <= max_idx
        dispTrace(i,handles);
    end
end


% --- Executes when user attempts to close trace_fig.
function trace_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to trace_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(hObject);
delete(hObject);
