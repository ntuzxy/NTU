function RP = AP_RP(bin_image, NUM_OBJ_MAX, HIST_X, HIST_Y, SLOT_X, SLOT_Y, XSIZE_MIN, YSIZE_MIN)
%
% Axies Projection based Region Proposal 
% By: Xueyong -Apr 2021-
% 
% INPUTS:
%   'bin_image'
%       binary image array with size of width*hight
%   'parameters'
%       NUM_OBJ_MAX
%       SLOT_X
%       SLOT_Y
%
% OUTPUTS:
%   'RP'
%       A struct of "Region Proposal" (RP) values with format
%           RP.x =  pixel X locations, a pair (x_start, x_stop) for one object, strictly positive integers only (0<RP.x<width)
%           RP.y =  pixel Y locations, a pair (y_start, y_stop) for one object, strictly positive integers only (0<RP.y<hight)
%           RP.n =  number of objects, strictly positive integers only (0<RP.n<NUM_OBJ_MAX)
%
%% 
% % load data
% % filt_bin_image = textread('../test/filt_bin_image_1.txt');
% filt_bin_image = importdata('../test/filt_bin_image_1.txt');
% 
% % parameters
% NUM_OBJ_MAX = 8;
% SLOT_X      = 4;
% SLOT_Y      = 4;
% XSIZE_MIN   = 4;
% YSIZE_MIN   = 2;
% HIST_X      = 10;
% HIST_Y      = 5;

x_start = zeros(NUM_OBJ_MAX,1);
x_stop  = zeros(NUM_OBJ_MAX,1);
y_start = zeros(NUM_OBJ_MAX,1);
y_stop  = zeros(NUM_OBJ_MAX,1);

[height, width] = size(bin_image);
%% 1) projection onto x-axis globally
x(1:width) = sum(bin_image(:,1:width)); % sum of each column
% filtering and sensing
N = x<HIST_X;
x(N) = 0;
num_obj_x = 0;
if x(1) % left edge case
    num_obj_x = num_obj_x + 1;
    x_start(num_obj_x) = 1;
end
for i = 2 : width
    if x(i) && ~x(i-1)
        num_obj_x = num_obj_x + 1;
        x_start(num_obj_x) = i;
    elseif ~x(i) && x(i-1)
        if i - x_start(num_obj_x) > XSIZE_MIN
            x_stop(num_obj_x) = i - 1;
        else % filtering narrow object (eg. human)
            num_obj_x = num_obj_x - 1;
        end
    elseif x(i) && i == width % right edge case
        x_stop(num_obj_x) = i;
    end
end
% merge fragmental object 
num_obj_valid_x = num_obj_x;
if num_obj_x > 1
    m = 0;
    merge = 1;
    while merge
        m = m + 1;
        if m < num_obj_valid_x
            if x_start(m+1) - x_stop(m) < SLOT_X
                x_stop(m)       = x_stop(m+1); % merge
                num_obj_valid_x = num_obj_valid_x - 1;
                for n = m+1 : num_obj_valid_x % shift 
                    x_start(n)  = x_start(n+1);
                    x_stop(n)   = x_stop(n+1);
                end
                m = m - 1;
            end
        else
            merge = 0;
        end
    end
end

%% 2) projection onto y-axis (locally)
y_1 = cell(NUM_OBJ_MAX,1);
y_2 = cell(NUM_OBJ_MAX,1);
x_n = num_obj_valid_x;
y_n = zeros(x_n,1);
yk_n = 0;
num_obj_valid_y = 0;
for k = 1: x_n
    y(1:height) = sum(bin_image(:,x_start(k):x_stop(k)),2); % sum of each row
    % filtering and sensing
    N = y<HIST_Y;
    y(N) = 0;
    y(height+1) = 0;
    for i = 2 : height+1
        if y(i) && ~y(i-1)
            y_n(k) = y_n(k) + 1;
            y_1{k,y_n(k)} = i;
        elseif ~y(i) && y(i-1) && y_n(k)>0
            if i - y_1{k,y_n(k)} > YSIZE_MIN
                y_2{k,y_n(k)} = i - 1;
            else % filtering narrow object (eg. human)
                y_n(k) = y_n(k) - 1;
            end
        end
    end
    % merge fragmental object 
    if y_n(k) > 1
        num_obj_valid_yk = y_n(k);
        m = 0;
        merge = 1;
        while merge
            m = m + 1;
            if m < num_obj_valid_yk
                if y_1{k,m+1} - y_2{k,m} < SLOT_Y
                    y_2{k,m}         = y_2{k,m+1}; % merge
                    num_obj_valid_yk = num_obj_valid_yk - 1;
                    for n = m+1 : num_obj_valid_yk % shift 
                        y_1{k,n} = y_1{k,n+1};
                        y_2{k,n} = y_2{k,n+1};
                    end
                    m = m - 1;
                end
            else
                merge = 0;
            end
        end
        y_n(k) = num_obj_valid_yk;
%     else % filtering narrow object (eg. human)
%         num_obj_valid_x = num_obj_valid_x - 1;
%         for n = 1 : num_obj_valid_x % shift 
%             x_start(n)  = x_start(n+1);
%             x_stop(n)   = x_stop(n+1);
%         end

%         for j = 1 : num_obj_valid_y
%             y_start(j + yk_n)  = y_1{k,num_obj_valid_y};
%             y_stop(j + yk_n)   = y_2{k,num_obj_valid_y};
%         end
%         yk_n = num_obj_valid_y;
    end
    for j = 1 : y_n(k)
        y_start(j + yk_n)  = y_1{k,j};
        y_stop(j + yk_n)   = y_2{k,j};
    end
    yk_n = y_n(k);
    num_obj_valid_y = num_obj_valid_y + y_n(k);
end
%% output RP info
% num_obj = num_obj_valid_x * (num_obj_valid_x == num_obj_valid_y); %check 
num_obj = min(num_obj_valid_x, num_obj_valid_y);
RP.x = zeros(2 * num_obj, 1);
RP.y = zeros(2 * num_obj, 1);
RP.n = num_obj;
if num_obj > 0 %valid num_obj
    for m = 1 : num_obj
        RP.x(2 * m - 1)   = x_start(m);
        RP.x(2 * m)       = x_stop(m);
        RP.y(2 * m - 1)   = y_start(m);
        RP.y(2 * m)       = y_stop(m);
    end
end

end

