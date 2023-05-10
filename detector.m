function varargout = detector(varargin)
% DETECTOR MATLAB code for detector.fig
%      DETECTOR, by itself, creates a new DETECTOR or raises the existing
%      singleton*.
%
%      H = DETECTOR returns the handle to a new DETECTOR or the handle to
%      the existing singleton*.
%
%      DETECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DETECTOR.M with the given input arguments.
%
%      DETECTOR('Property','Value',...) creates a new DETECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before detector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to detector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help detector

% Last Modified by GUIDE v2.5 29-Nov-2022 11:37:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @detector_OpeningFcn, ...
                   'gui_OutputFcn',  @detector_OutputFcn, ...
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


% --- Executes just before detector is made visible.
function detector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to detector (see VARARGIN)

% Choose default command line output for detector
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes detector wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = detector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in button.
function button_Callback(hObject, eventdata, handles)
% hObject    handle to button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global a;
[f,path]=uigetfile('*.*','Pick a file');  % just obtains the filename and its path
f=strcat(path,f);
a=imread(f);
axes(handles.axes1);
imshow(a);




% --- Executes on button press in compute.
function compute_Callback(hObject, eventdata, handles)
% hObject    handle to compute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global a;

%a = get(handles.axes1,'value');
% conversion to gray scale image
b=im2gray(a);
%figure('Name','Gray Scale Image');
%imshow(b);
%impixelinfo; % it shows info in image : (X,Y) -> Intensity
%val = size(b);
%fprintf("The Dimension : %g %g\n",val(1),val(2));

% IMAGE PRE-PROCESSING
%figure('Name','Histogram');
%imhist(b);
c=b>20;   % only chooses pixels whose intensity is more than 20, threshold
%figure('Name','Thresholding');  % it is done by observing histogram of it
%imshow(c);

% there are small holes , hence filling these holes
d=imfill(c,'holes'); % which are not connected with edge
%figure('Name','Hole Filling');
%imshow(d);

% it will remove small objects from binary image , for removing noise 
e=bwareaopen(d,1000);
%figure('Name','Removing Noise');
%imshow(e);

% here masking will be done, now we need to mask original image using this
% masked image to extract only masking portion from original image.
% the mask is gray channel & will consider it as matrix of binary numbers 
% & original is rgb, hence need to multiply with r,g,b channels 
f=uint8(double(a).*repmat(e,[1 1 3])); % replicate
%figure('Name','Pre-Processed Image');
%imshowpair(a,f,"montage");
axes(handles.axes2);
imshow(f);
title("Masked Image");

% need to contrast image , only require high intensity regions of image
g=imadjust(f,[0.3 0.7],[])+50; % portion of image having intensity less than 0.3 is suppressed
%figure('Name','Contrasted Image');
%imshow(g);
%impixelinfo;

% again need to convert to gray scale as pre-processed was rgb
h=rgb2gray(g);
%figure('Name','Pre-Processed Gray Scale');
%imshow(h);
%impixelinfo;
axes(handles.axes3);
imshow(h);
title("Contrasted Image");

% now, it is clearly distinguisable that mid area will be bright having
% high intensity if kidney stone is present

% there are several regions which are not our point of interest and are
% isolated from middle portion, where chances are high for detecting kidney
% stone -> hence, need to filter out -> morphological operations

% The median filter is the filtering technique used for noise removal from
% images and signals. Median filter is very crucial in the image processing 
% field as it is well known for the preservation of edges during noise removal.

% since 2d gray scale, 5 by 5 neighbourhood -> every pixel takes median
% values of their neighbours
i=medfilt2(h,[5 5]);
%figure('Name','Median Filtering');
%imshow(i);
%impixelinfo;

% now, we will extract only that part of image whose intensity is high
j = i>250; % logical (binary) matrix
%figure('Name','Thresholding');
%imshow(j);
%impixelinfo;
axes(handles.axes4);
imshow(j);
title("High Intensity Filtering");


% now, from the domain knowledge, we will reduce the image to crop out
% center portion to check whether stone is present or not


[height,width] = size(j);
% kidney stone will be mostly in middle region (constraint)
x_coor = round(height/2.2);
y_coor = round(width/3.2);

% region of interest

roi_x = [x_coor,x_coor+250,x_coor+250,x_coor];
roi_y = [y_coor,y_coor,y_coor+50,y_coor+50];

% selecting polygonal region of interest from image for masking out that
% region
k = roipoly(j,roi_x,roi_y);
%figure('Name','Area of Interest');
%imshow(k);

% multiplying roi mask with filtered image
l = j.*double(k);
%figure('Name','ROI MASKED IMAGE');
%imshow(l);
%impixelinfo;

m = bwareaopen(l,50);  % if pixel is <5, then we will we filter it out
%figure('Name','Final Image');
%imshow(m);

axes(handles.axes5);
imshow(m);
title("Region Of Interest MASK");

[~,nitems] = bwlabel(m);  % detects no. of connected components
if(nitems>0)
    %fprintf("Kidney Stone is Detected!\n");
    set(handles.ans,'string',"Kidney Stone Detected!");
else
    %fprintf("No Stone Detected\n");
    set(handles.ans,'string',"No Stone Detected!");
end
