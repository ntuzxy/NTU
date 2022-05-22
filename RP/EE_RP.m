function RP = EE_RP(filt_bin_image, NUM_OBJ_MAX, SLOT_X, SLOT_Y, XSIZE_MIN)
%
% Edge Event based Region Proposal 
% By: Xueyong -Dec 2019-
% 
% INPUTS:
%   'filt_bin_image'
%       the filtered image array with size of width*hight
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
FILTER_X    = 4;
FILTER_Y    = 4;

[hight, width] = size(filt_bin_image);
data = 0;
data_last = 0;
num_obj = 0;
x_start = zeros(NUM_OBJ_MAX,1);
x_stop  = zeros(NUM_OBJ_MAX,1);
y_start = zeros(NUM_OBJ_MAX,1);
y_stop  = zeros(NUM_OBJ_MAX,1);

if num_obj < NUM_OBJ_MAX
    for j = 1 : hight %scan row
        for i = 1 : width %scan column
            if num_obj < NUM_OBJ_MAX
                data = filt_bin_image(j,i);
                if data && ~data_last %rising edge
                    num_obj = num_obj + 1;
                    x_start(num_obj) = i;
                    y_start(num_obj) = j;
                elseif ~data && data_last %falling edge
                    if y_start(num_obj) == j %falling edge and rising edge at the same row
                        x_stop(num_obj) = i;
                        y_stop(num_obj) = j;
                        [x_start, x_stop, y_start, y_stop, num_obj] = EE_RP_update(x_start, x_stop, y_start, y_stop, num_obj, SLOT_X, SLOT_Y, XSIZE_MIN);
                    else  %falling edge and rising edge at the different row
                        %object at the right edge
                        x_stop(num_obj) = width;
                        y_stop(num_obj) = y_start(num_obj);
                        [x_start, x_stop, y_start, y_stop, num_obj] = EE_RP_update(x_start, x_stop, y_start, y_stop, num_obj, SLOT_X, SLOT_Y, XSIZE_MIN);
                        %object at the left edge
                        if i>1
                            num_obj = num_obj + 1;
                            x_start(num_obj) = 1;
                            x_stop(num_obj)  = i;
                            y_start(num_obj) = j;
                            y_stop(num_obj)  = j;
                            [x_start, x_stop, y_start, y_stop, num_obj] = EE_RP_update(x_start, x_stop, y_start, y_stop, num_obj, SLOT_X, SLOT_Y, XSIZE_MIN);
                        end
                    end
                end
                data_last = data;
            end %for num_obj < NUM_OBJ_MAX
        end %for i = 1 : width %scan column
    end %for j = 1 : hight %scan row

end %if num_obj < NUM_OBJ_MAX



%% output RP info
noise_num = 0;
if num_obj %include noise
    for m = 1 : num_obj
        if (x_stop(m)-x_start(m) < FILTER_X || y_stop(m)-y_start(m) < FILTER_Y) %filtering
            num_obj_valid = num_obj - 1;
            for n = m : num_obj_valid
                x_start(n)  = x_start(n+1);
                x_stop(n)   = x_stop(n+1);
                y_start(n)  = y_start(n+1);
                y_stop(n)   = y_stop(n+1);
            end
            noise_num = noise_num + 1;
        end
    end
end
num_obj = num_obj - noise_num;
RP.x = zeros(2 * num_obj, 1);
RP.y = zeros(2 * num_obj, 1);
RP.n = num_obj;
if num_obj %valid num_obj
    for m = 1 : num_obj
        RP.x(2 * m - 1)   = x_start(m);
        RP.x(2 * m)       = x_stop(m) - 1;
        RP.y(2 * m - 1)   = y_start(m);
        RP.y(2 * m)       = y_stop(m);
    end
end

end

