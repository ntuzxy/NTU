% function for EE_RP (Edge Event based Region Proposal)
% update RP at the falling edge
function [x_start, x_stop, y_start, y_stop, num_obj] = EE_RP_update(x_start, x_stop, y_start, y_stop, num_obj, SLOT_X, SLOT_Y, XSIZE_MIN)
    if  x_stop(num_obj) - x_start(num_obj) > XSIZE_MIN
        if num_obj > 1 %compare current detected object with previous detected objects and check if they are the same object
        %   for n = 1 : num_obj-1
            n = 1;
            while n < num_obj
                space_left  = x_start(num_obj) - x_stop(n);
                space_right = x_start(n) - x_stop(num_obj);
                space_top   = y_start(num_obj) - y_stop(n);
                if ((space_left > 0 && space_left < SLOT_X) || ...
                    (space_right > 0 && space_right < SLOT_X) || ...
                    (space_left <= 0 && space_right <= 0)) && (space_top < SLOT_Y) % merge objects
                    x_start(n) = min(x_start(num_obj), x_start(n));
                    x_stop(n)  = max(x_stop(num_obj), x_stop(n));
                    y_stop(n)  = max(y_stop(num_obj), y_stop(n));
                    num_obj = num_obj - 1;
                    n = n -1;
                end
                n = n + 1;
            end
        end

    else % ignore the noise pixels
        num_obj = num_obj - 1;
    end
%     % ignore the noise pixels
%     if x_stop(num_obj) - x_start(num_obj) < XSIZE_MIN
%         num_obj = num_obj - 1;
%     end
end
