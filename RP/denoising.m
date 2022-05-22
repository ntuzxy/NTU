function output_img = denoising(input_img, m ,n)
medfilt_en = 1;
plot_en  = 0;
%% 2-D discrete cosine transform
th = 0.5;
%获取图片尺寸
[h,w]=size(input_img);
%DCT变换
Y=dct2(input_img); 
I=zeros(h,w);
%高频屏蔽
I(1:h/3,1:w/3)=1; 
Ydct=Y.*I;
%逆DCT变换
Y=(idct2(Ydct)); 
%还原成二值图像
for j= 1 : h
    for i = 1 : w
        if Y(j,i) > th
            Y(j,i) = 1;
        else
            Y(j,i) = 0;
        end
    end
end

%% 2-D median filtering
% m-by-n neighborhood 
% m = 4;
% n = 4;
output_img_medfilt = medfilt2(input_img,[m,n]);
%还原成二值图像
for j= 1 : h
    for i = 1 : w
        if output_img_medfilt(j,i) > 0
            output_img_medfilt(j,i) = 1;
        else
            output_img_medfilt(j,i) = 0;
        end
    end
end

%% selection
if medfilt_en
    output_img = output_img_medfilt;
else
    output_img = Y;
end

%% plot
if plot_en 
    figure;
    subplot(121); 
    imshow(input_img);
    subplot(122);
    imshow(output_img);
end

end
