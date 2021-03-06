if ~exist('rosette_calibration','var')
    rosette_calibration = 0;
end;

if (rosette_calibration)
    % Guesses for the intrinsic parameters.
    fg = [ 2300.044453320904  2304.757690230091  ]';
    cg = [924.743157649778  1282.463968890109   ]';
    kg = [-0.443251898487364   0.247922214991804  -0.000682045390384  0.000326391030429   -0.092405396596532]';
end;

if exist(['wintx_' num2str(kk)]),
    eval(['wintxkk = wintx_' num2str(kk) ';']);
    if ~isempty(wintxkk) & ~isnan(wintxkk),
        eval(['wintx = wintx_' num2str(kk) ';']);
        eval(['winty = winty_' num2str(kk) ';']);        
    end;
end;

if (rosette_calibration),
    wintx = 20;
    winty = 20;
end;
        
fprintf(1,'Using (wintx,winty)=(%d,%d) - Window size = %dx%d      (Note: To reset the window size, run script clearwin)\n',wintx,winty,2*wintx+1,2*winty+1);

grid_success = 0;

while (~grid_success)
    bad_clicks = 1;

    while bad_clicks,

        figure(2); clf;
        image(I);
        colormap(map);
        axis image;
        set(2,'color',[1 1 1]);
        title(['Click on the four extreme corners of the rectangular pattern (first corner = origin)... Image ' num2str(kk)]);
        disp('Click on the four extreme corners of the rectangular complete pattern (the first clicked corner is the origin)...');

        if (rosette_calibration)
            position_fig = get(2,'position');
            position_fig(3:4) = [674 824];
            set(2,'position',position_fig);
            findfigs;
        end;
        
        wintx_save = wintx;
        winty_save = winty;

        if (rosette_calibration)
            wintx = 30;
            winty = 30;
        end;

        x= [];y = [];
        figure(2); hold on;
        for count = 1:4,
            [xi,yi] = ginput4(1);
            [xxi] = cornerfinder([xi;yi],I,winty,wintx);
            xi = xxi(1);
            yi = xxi(2);
            figure(2);
            plot(xi,yi,'+','color',[ 1.000 0.314 0.510 ],'linewidth',2);
            plot(xi + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],yi + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1.000 0.314 0.510 ],'linewidth',2);
            x = [x;xi];
            y = [y;yi];
            plot(x,y,'-','color',[ 1.000 0.314 0.510 ],'linewidth',2);
            drawnow;
        end;
        plot([x;x(1)],[y;y(1)],'-','color',[ 1.000 0.314 0.510 ],'linewidth',2);
        drawnow;
        hold off;

        wintx = wintx_save;
        winty = winty_save;

        [Xc,good,bad,type] = cornerfinder([x';y'],I,winty,wintx); % the four corners

        bad_clicks = (sum(bad)>0);

    end;

    x = Xc(1,:)';
    y = Xc(2,:)';

    % Sort the corners:
    x_mean = mean(x);
    y_mean = mean(y);
    x_v = x - x_mean;
    y_v = y - y_mean;

    theta = atan2(-y_v,x_v);
    [junk,ind] = sort(theta);

    [junk,ind] = sort(mod(theta-theta(1),2*pi));

    ind = ind([4 3 2 1]); %-> New: the Z axis is pointing uppward

    x = x(ind);
    y = y(ind);

    if (rosette_calibration)
        % Enforce the orering convention for the Rosette calibration.
        % get the first two points by sorting the x:
        [x_junk,ind_sort_x] = sort(x);
        first_two_points = ind_sort_x(1:2);
        last_two_points = ind_sort_x(3:4);

        [y_junk, ind_sort_y] = sort(y(first_two_points));
        ind1 = first_two_points(ind_sort_y(2));
        ind2 = first_two_points(ind_sort_y(1));
        [y_junk, ind_sort_y] = sort(y(last_two_points));
        ind3 = last_two_points(ind_sort_y(1));
        ind4 = last_two_points(ind_sort_y(2));

        ind_resort = [ind1;ind2;ind3;ind4];
        x = x(ind_resort);
        y = y(ind_resort);
    end;

    x1= x(1); x2 = x(2); x3 = x(3); x4 = x(4);
    y1= y(1); y2 = y(2); y3 = y(3); y4 = y(4);

    % Find center:
    p_center = cross(cross([x1;y1;1],[x3;y3;1]),cross([x2;y2;1],[x4;y4;1]));
    x5 = p_center(1)/p_center(3);
    y5 = p_center(2)/p_center(3);

    % center on the X axis:
    x6 = (x3 + x4)/2;
    y6 = (y3 + y4)/2;

    % center on the Y axis:
    x7 = (x1 + x4)/2;
    y7 = (y1 + y4)/2;

    % Direction of displacement for the X axis:
    vX = [x6-x5;y6-y5];
    vX = vX / norm(vX);

    % Direction of displacement for the X axis:
    vY = [x7-x5;y7-y5];
    vY = vY / norm(vY);

    % Direction of diagonal:
    vO = [x4 - x5; y4 - y5];
    vO = vO / norm(vO);

    delta = 30;

    figure(2); image(I);
    axis image;
    colormap(map);
    hold on;
    plot([x;x(1)],[y;y(1)],'g-');
    plot(x,y,'og');
    hx=text(x6 + delta * vX(1) ,y6 + delta*vX(2),'X');
    set(hx,'color','g','Fontsize',14);
    hy=text(x7 + delta*vY(1), y7 + delta*vY(2),'Y');
    set(hy,'color','g','Fontsize',14);
    hO=text(x4 + delta * vO(1) ,y4 + delta*vO(2),'O','color','g','Fontsize',14);
    for iii = 1:4,
        text(x(iii),y(iii),num2str(iii));
    end;
    hold off;

    if manual_squares,
        n_sq_x = input(['Number of squares along the X direction ([]=' num2str(n_sq_x_default) ') = ']); %6
        if isempty(n_sq_x), n_sq_x = n_sq_x_default; end;
        n_sq_y = input(['Number of squares along the Y direction ([]=' num2str(n_sq_y_default) ') = ']); %6
        if isempty(n_sq_y), n_sq_y = n_sq_y_default; end;
        grid_success = 1;
    else
        if (rosette_calibration)
            n_sq_x1 = count_squares_distorted(I,x1,y1,x2,y2,wintx, fg, cg, kg);
            n_sq_x2 = count_squares_distorted(I,x3,y3,x4,y4,wintx, fg, cg, kg);
            n_sq_y1 = count_squares_distorted(I,x2,y2,x3,y3,wintx, fg, cg, kg);
            n_sq_y2 = count_squares_distorted(I,x4,y4,x1,y1,wintx, fg, cg, kg);
        else
            % Try to automatically count the number of squares in the grid
            n_sq_x1 = count_squares(I,x1,y1,x2,y2,wintx);
            n_sq_x2 = count_squares(I,x3,y3,x4,y4,wintx);
            n_sq_y1 = count_squares(I,x2,y2,x3,y3,wintx);
            n_sq_y2 = count_squares(I,x4,y4,x1,y1,wintx);
        end;

        % If could not count the number of squares, enter manually
        if ((n_sq_x1~=n_sq_x2)||(n_sq_y1~=n_sq_y2)||...
                (min([n_sq_x1 n_sq_x2 n_sq_y1 n_sq_y2] < 0))),
            if (rosette_calibration)
                % Try harder using an existing intrinsic model:
                n_sq_x1 = count_squares_distorted(I,x1,y1,x2,y2,wintx, fg, cg, kg);
                n_sq_x2 = count_squares_distorted(I,x3,y3,x4,y4,wintx, fg, cg, kg);
                n_sq_y1 = count_squares_distorted(I,x2,y2,x3,y3,wintx, fg, cg, kg);
                n_sq_y2 = count_squares_distorted(I,x4,y4,x1,y1,wintx, fg, cg, kg);
            end;
            if ((n_sq_x1~=n_sq_x2)||(n_sq_y1~=n_sq_y2)||...
                    (min([n_sq_x1 n_sq_x2 n_sq_y1 n_sq_y2] < 0))),
                if ~rosette_calibration,
                    disp('Could not count the number of squares in the grid. Enter manually.');
                    n_sq_x = input(['Number of squares along the X direction ([]=' num2str(n_sq_x_default) ') = ']); %6
                    if isempty(n_sq_x), n_sq_x = n_sq_x_default; end;
                    n_sq_y = input(['Number of squares along the Y direction ([]=' num2str(n_sq_y_default) ') = ']); %6
                    if isempty(n_sq_y), n_sq_y = n_sq_y_default; end;
                    grid_success = 1;
                else
                    grid_success = 0;
                end;
            else
                n_sq_x = n_sq_x1;
                n_sq_y = n_sq_y1;
                grid_success = 1;
            end;
        else
            n_sq_x = n_sq_x1;
            n_sq_y = n_sq_y1;
            grid_success = 1;
        end;
    end;
    if ~grid_success
        fprintf(1,'Invalid grid. Try again.\n');
    end;
end;

n_sq_x_default = n_sq_x;
n_sq_y_default = n_sq_y;


if (exist('dX')~=1)||(exist('dY')~=1), % This question is now asked only once
    % Enter the size of each square
    dX = input(['Size dX of each square along the X direction ([]=' num2str(dX_default) 'm) = ']);
    dY = input(['Size dY of each square along the Y direction ([]=' num2str(dY_default) 'm) = ']);
    if isempty(dX), dX = dX_default; else dX_default = dX; end;
    if isempty(dY), dY = dY_default; else dY_default = dY; end;
else
    fprintf(1,['Size of each square along the X direction: dX=' num2str(dX) 'm\n']);
    fprintf(1,['Size of each square along the Y direction: dY=' num2str(dY) 'm   (Note: To reset the size of the squares, clear the variables dX and dY)\n']);
end;

if (~rosette_calibration)
    % Compute the inside points through computation of the planar homography (collineation)
    a00 = [x(1);y(1);1];
    a10 = [x(2);y(2);1];
    a11 = [x(3);y(3);1];
    a01 = [x(4);y(4);1];

    % Compute the planar collineation: (return the normalization matrix as well)
    [Homo,Hnorm,inv_Hnorm] = compute_homography([a00 a10 a11 a01],[0 1 1 0;0 0 1 1;1 1 1 1]);

    % Build the grid using the planar collineation:
    x_l = ((0:n_sq_x)'*ones(1,n_sq_y+1))/n_sq_x;
    y_l = (ones(n_sq_x+1,1)*(0:n_sq_y))/n_sq_y;
    pts = [x_l(:) y_l(:) ones((n_sq_x+1)*(n_sq_y+1),1)]';
    XX = Homo*pts;
    XX = XX(1:2,:) ./ (ones(2,1)*XX(3,:));
else
    [x_pn] = normalize_pixel([x' ; y'] - 1,fg,cg,kg,0);
    
    % Compute the inside points through computation of the planar homography (collineation)
    a00 = [x_pn(1,1);x_pn(2,1);1];
    a10 = [x_pn(1,2);x_pn(2,2);1];
    a11 = [x_pn(1,3);x_pn(2,3);1];
    a01 = [x_pn(1,4);x_pn(2,4);1];

    % Compute the planar collineation: (return the normalization matrix as well)
    [Homo,Hnorm,inv_Hnorm] = compute_homography([a00 a10 a11 a01],[0 1 1 0;0 0 1 1;1 1 1 1]);

    % Build the grid using the planar collineation:
    x_l = ((0:n_sq_x)'*ones(1,n_sq_y+1))/n_sq_x;
    y_l = (ones(n_sq_x+1,1)*(0:n_sq_y))/n_sq_y;
    pts = [x_l(:) y_l(:) ones((n_sq_x+1)*(n_sq_y+1),1)]';

    XXpn = Homo*pts;
    XXpn = XXpn(1:2,:) ./ (ones(2,1)*XXpn(3,:));

    XX = apply_distortion2(XXpn,kg);

    XX(1,:) = fg(1)*XX(1,:) + cg(1) + 1;
    XX(2,:) = fg(2)*XX(2,:) + cg(2) + 1;
end;

% Complete size of the rectangle
W = n_sq_x*dX;
L = n_sq_y*dY;

if (~rosette_calibration)
    
%%%%%%%%%%%%%%%%%%%%%%%% ADDITIONAL STUFF IN THE CASE OF HIGHLY DISTORTED IMAGES %%%%%%%%%%%%%
figure(2);
hold on;
plot(XX(1,:),XX(2,:),'r+');
title('The red crosses should be close to the image corners');
hold off;

disp('If the guessed grid corners (red crosses on the image) are not close to the actual corners,');
disp('it is necessary to enter an initial guess for the radial distortion factor kc (useful for subpixel detection)');
quest_distort = input('Need of an initial guess for distortion? ([]=no, other=yes) ');

quest_distort = ~isempty(quest_distort);

if quest_distort,
    % Estimation of focal length:
    c_g = [size(I,2);size(I,1)]/2 + .5;
    f_g = Distor2Calib(0,[[x(1) x(2) x(4) x(3)] - c_g(1);[y(1) y(2) y(4) y(3)] - c_g(2)],1,1,4,W,L,[-W/2 W/2 W/2 -W/2;L/2 L/2 -L/2 -L/2; 0 0 0 0],100,1,1);
    f_g = mean(f_g);
    script_fit_distortion;
end;
%%%%%%%%%%%%%%%%%%%%% END ADDITIONAL STUFF IN THE CASE OF HIGHLY DISTORTED IMAGES %%%%%%%%%%%%%

end;



Np = (n_sq_x+1)*(n_sq_y+1);

disp('Corner extraction...');

grid_pts = cornerfinder(XX,I,winty,wintx); %%% Finds the exact corners at every points!

%save all_corners x y grid_pts

grid_pts = grid_pts - 1; % subtract 1 to bring the origin to (0,0) instead of (1,1) in matlab (not necessary in C)

ind_corners = [1 n_sq_x+1 (n_sq_x+1)*n_sq_y+1 (n_sq_x+1)*(n_sq_y+1)]; % index of the 4 corners
ind_orig = (n_sq_x+1)*n_sq_y + 1;
xorig = grid_pts(1,ind_orig);
yorig = grid_pts(2,ind_orig);
dxpos = mean([grid_pts(:,ind_orig) grid_pts(:,ind_orig+1)]');
dypos = mean([grid_pts(:,ind_orig) grid_pts(:,ind_orig-n_sq_x-1)]');


x_box_kk = [grid_pts(1,:)-(wintx+.5);grid_pts(1,:)+(wintx+.5);grid_pts(1,:)+(wintx+.5);grid_pts(1,:)-(wintx+.5);grid_pts(1,:)-(wintx+.5)];
y_box_kk = [grid_pts(2,:)-(winty+.5);grid_pts(2,:)-(winty+.5);grid_pts(2,:)+(winty+.5);grid_pts(2,:)+(winty+.5);grid_pts(2,:)-(winty+.5)];


figure(3);
image(I); axis image; colormap(map); hold on;
plot(grid_pts(1,:)+1,grid_pts(2,:)+1,'r+');
plot(x_box_kk+1,y_box_kk+1,'-b');
plot(grid_pts(1,ind_corners)+1,grid_pts(2,ind_corners)+1,'mo');
plot(xorig+1,yorig+1,'*m');
h = text(xorig+delta*vO(1),yorig+delta*vO(2),'O');
set(h,'Color','m','FontSize',14);
h2 = text(dxpos(1)+delta*vX(1),dxpos(2)+delta*vX(2),'dX');
set(h2,'Color','g','FontSize',14);
h3 = text(dypos(1)+delta*vY(1),dypos(2)+delta*vY(2),'dY');
set(h3,'Color','g','FontSize',14);
xlabel('Xc (in camera frame)');
ylabel('Yc (in camera frame)');
title('Extracted corners');
zoom on;
drawnow;
hold off;


Xi = reshape(([0:n_sq_x]*dX)'*ones(1,n_sq_y+1),Np,1)';
Yi = reshape(ones(n_sq_x+1,1)*[n_sq_y:-1:0]*dY,Np,1)';
Zi = zeros(1,Np);

Xgrid = [Xi;Yi;Zi];


% All the point coordinates (on the image, and in 3D) - for global optimization:

x = grid_pts;
X = Xgrid;


% Saves all the data into variables:

eval(['dX_' num2str(kk) ' = dX;']);
eval(['dY_' num2str(kk) ' = dY;']);  

eval(['wintx_' num2str(kk) ' = wintx;']);
eval(['winty_' num2str(kk) ' = winty;']);

eval(['x_' num2str(kk) ' = x;']);
eval(['X_' num2str(kk) ' = X;']);

eval(['n_sq_x_' num2str(kk) ' = n_sq_x;']);
eval(['n_sq_y_' num2str(kk) ' = n_sq_y;']);
