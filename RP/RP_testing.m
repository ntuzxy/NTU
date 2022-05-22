%% Region Proposal Testing
% To test and compare the proposed two RP algorithm: 
%   1) Edge Event Driven Region Proposal (EEDRP); 
%   2) Axies Projection Based Region Proposal (APBRP).
%   NOTE: APBRP is sensitive to parameters, need to be optimized
% By: Xueyong -Apr 2021-

%%
%%% parameters
X_SIZE  = 320;
Y_SIZE  = 240;
WIDTH   = 240;
HIGHT   = 180;
NUM_OBJ_MAX = 16;
% the maxmum slot (x/y dirction) of the same object
SLOT_X_EEDRP = 4; 
SLOT_Y_EEDRP = 4; 
SLOT_X_APBRP = 8; 
SLOT_Y_APBRP = 8; 
% the minimum consecutive range (x/y dirction) for a valid object
XSIZE_MIN_EEDRP = 4; 
YSIZE_MIN_EEDRP = 4; 
XSIZE_MIN_APBRP = 2; 
YSIZE_MIN_APBRP = 2; 
% the minimum histogram threshold (x/y) for a valid object
HIST_X_APBRP = 10;  
HIST_Y_APBRP = 8;%5; 
% switch
APBRP_EN    = 1;%1;
show_image  = 1;

colors = {'red','green','blue','cyan','magenta','yellow','red','green'};

%%% load image directory
% path1 = './testing_data/server_brainlab/20180711_ENG_3pm_12mm_02_data/'; %/media/project2/media/project2/common/recovered_disc/deepak/data_for_Lavanya/20180711_ENG_3pm_12mm_02_data
% path1 = './testing_data/server_brainlab/20180711_Site1_3pm_12mm_01_HW_CNN_Test_data/'; %/code/deepak/20180711_Site1_3pm_12mm_01_HW_CNN_Test_data
path1 = '/home/zhangxy/Documents/MATLAB/CNN_testing/testing_data/server_brainlab/20180711_ENG_3pm_12mm_02_data/';
for img = 57:12887
    % load image 
    path2 = ['image_',num2str(img)];
    file_name_pos = [path2,'_0'];%'image_1006_0';
    file_name_neg = [path2,'_1'];%'image_1006_1';
    img_pos = load([path1,path2,'/',file_name_pos]); % the foramt is 320x240 data in a column
    img_neg = load([path1,path2,'/',file_name_neg]); % the foramt is 320x240 data in a column

    % resize image from 320x240 to 230x180 for better visualize
    img_data_pos = zeros(HIGHT,WIDTH);
    img_data_neg = zeros(HIGHT,WIDTH);
    for j=1:HIGHT
        for i=1:WIDTH
            img_data_pos(j,i) = img_pos((j-1)*X_SIZE+i);
            img_data_neg(j,i) = img_neg((j-1)*X_SIZE+i);
        end
    end
    img_data_or = img_data_pos | img_data_neg; % combine pos and neg images
    
    % EEDRP
    EEDRP = EE_RP(img_data_or, NUM_OBJ_MAX, SLOT_X_EEDRP, SLOT_Y_EEDRP, XSIZE_MIN_EEDRP);
    num_ee = EEDRP.n;
    rp_ee = num_ee;
    ind = 1;
    for i = 1:num_ee
        rp_ee = [rp_ee, EEDRP.x(ind), EEDRP.y(ind), EEDRP.x(ind+1), EEDRP.y(ind+1)];
        ind = ind+2;
    end
    % APBRP
    if APBRP_EN
    APBRP = AP_RP(img_data_or, NUM_OBJ_MAX, HIST_X_APBRP, HIST_Y_APBRP, SLOT_X_APBRP, SLOT_Y_APBRP, XSIZE_MIN_APBRP, YSIZE_MIN_APBRP);
    num_ap = APBRP.n;
    else
    num_ap = 0;
    end
    rp_ap = num_ap;
    ind = 1;
    for i = 1:num_ap
        rp_ap = [rp_ap, APBRP.x(ind), APBRP.y(ind), APBRP.x(ind+1), APBRP.y(ind+1)];
        ind = ind+2;
    end
    if show_image
        %plot image
    %     fig = figure(1);
        subplot(1,2,1); %image_pos
    %     imagesc(img_data_pos);
        imshow(img_data_pos); axis on;
    %     title(['Current Image: ',cats{classID}]);
        title(['Postive Image: ',num2str(img)]);
        subplot(1,2,2); %image_neg
    %     imagesc(img_data_neg);
        imshow(img_data_neg); axis on;
    %     title(['Current Image: ',cats{classID}]);
        title(['Negtive Image: ',num2str(img)]);
    
        %plot bounding box of EEDRP
        num_ee = rp_ee(1);
        for i = 1:num_ee
            A= [rp_ee(4*i-2),rp_ee(4*i-1),rp_ee(4*i)-rp_ee(4*i-2),rp_ee(4*i+1)-rp_ee(4*i-1)]; %bounding box (x,y,w,h)
            subplot(1,2,1);
            rectangle('Position',A,'EdgeColor',colors{i},'LineWidth',1);
            subplot(1,2,2);
            rectangle('Position',A,'EdgeColor',colors{i},'LineWidth',1);
        end
    
        %plot bounding box of APBRP
        num_ap = rp_ap(1);
        for i = 1:num_ap
            A= [rp_ap(4*i-2),rp_ap(4*i-1),rp_ap(4*i)-rp_ap(4*i-2),rp_ap(4*i+1)-rp_ap(4*i-1)]; %bounding box (x,y,w,h)
            subplot(1,2,1);
            rectangle('Position',A,'EdgeColor',colors{i},'LineWidth',1,'LineStyle','-.');
            subplot(1,2,2);
            rectangle('Position',A,'EdgeColor',colors{i},'LineWidth',1,'LineStyle','-.');
        end
        pause(0.5)
    end
end

