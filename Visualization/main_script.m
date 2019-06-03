clc;
close all;
clear variables; %clear classes;
rand('state',0); % rand('state',sum(100*clock));
dbstop if error;


%% basic setup for reading text file and GPS data

% import GPS data in UTM coordinate
textFileDir = 'device-orientation.txt';
delimiter = ' ';
headerlinesIn = 0;
textDataGPS = importdata(textFileDir, delimiter, headerlinesIn);

% convert GPS/INS to SE(3) pose
[pose, lat, lon] = convertGPS2Pose(textDataGPS);
M = size(lat,1);


%% main script for GPS visualization

% plot trajectory on Google map
figure;
plot(lon, lat, 'k', 'LineWidth', 3); hold on;
plot_google_map('maptype', 'roadmap', 'APIKey', 'AIzaSyB_uD1rGjX6MJkoQgSDyjHkbdu-b-_5Bjg');
legend('GPS');
xlabel('Longitude'); ylabel('Latitude'); hold off;


%
R_gi = zeros(3,3,M);
p_gi = zeros(3,M);
for k = 1:M
    % pose of GPS/INS (R,p)
    R_gi(:,:,k) = pose{k}(1:3,1:3);
    p_gi(:,k) = pose{k}(1:3,4);
end


figure; hold on; axis equal; grid on;
L = 150; % coordinate axis length
A = [0 0 0 1; L 0 0 1; 0 0 0 1; 0 L 0 1; 0 0 0 1; 0 0 L 1]';
for k = 1:100:M
    T = [ R_gi(:,:,k), p_gi(:,k);
        zeros(1,3),           1; ];
    B = T * A;
    plot3(B(1,1:2),B(2,1:2),B(3,1:2),'-r','LineWidth',1);  % x: red
    plot3(B(1,3:4),B(2,3:4),B(3,3:4),'-g','LineWidth',1);  % y: green
    plot3(B(1,5:6),B(2,5:6),B(3,5:6),'-b','LineWidth',1);  % z: blue
end
title('ground truth trajectory of GPS/INS sensor and camera')
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');

% figure options
f = FigureRotator(gca());


%%

% figure;
% lat = [48.8708 51.5188 41.9260 40.4312 52.523 37.982];
% lon = [2.4131 -0.1300 12.4951 -3.6788 13.415 23.715];
% plot(lon,lat,'.r','MarkerSize',20)
% plot_google_map('apiKey', 'AIzaSyB_uD1rGjX6MJkoQgSDyjHkbdu-b-_5Bjg')


%% basic setup for reading LAS LiDAR format

% import LAS data
LASFileDir = 'G:/HyundaiMnsoftMMSdataset/V1C32_K_N_A_190219_2_6003_7.las';
LASData = lasdata(LASFileDir, 'loadall');



interval = 50;

figure;
plot3(LASData.x(1:interval:end), LASData.y(1:interval:end), LASData.z(1:interval:end), 'k.');
grid on; axis equal;






