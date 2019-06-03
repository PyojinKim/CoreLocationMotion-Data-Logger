clc;
close all;
clear variables; %clear classes;
rand('state',0); % rand('state',sum(100*clock));
dbstop if error;


%% 1) GPS location

% parsing GPS location text
textFileDir = 'GPS-location.txt';
delimiter = ' ';
headerlinesIn = 0;
textGPSLocationData = importdata(textFileDir, delimiter, headerlinesIn);
deviceLatitude = textGPSLocationData(:,2);
deviceLongitude = textGPSLocationData(:,3);

% plot trajectory on Google map
figure;
plot(deviceLongitude, deviceLatitude,'.r','MarkerSize',20); hold on;
plot_google_map('maptype', 'roadmap', 'APIKey', 'AIzaSyB_uD1rGjX6MJkoQgSDyjHkbdu-b-_5Bjg');
legend('CLLocation');
xlabel('Longitude'); ylabel('Latitude'); hold off;


%% 2) device orientation

% parsing device orientation text
textFileDir = 'device-orientation.txt';
delimiter = ' ';
headerlinesIn = 0;
textOrientationData = importdata(textFileDir, delimiter, headerlinesIn);
deviceOrientationTime = textOrientationData(:,1).';
deviceOrientationTime = (deviceOrientationTime - deviceOrientationTime(1)) ./ 1000000000;
deviceOrientationData = textOrientationData(:,[5 2 3 4]).';
numData = size(deviceOrientationData,2);

% convert from unit quaternion to rotation matrix & roll/pitch/yaw
R_gb = zeros(3,3,numData);
rpy_gb = zeros(3,numData);
for k = 1:numData
    R_gb(:,:,k) = q2r(deviceOrientationData(:,k));
    rpy_gb(:,k) = rotmtx2angle(inv(R_gb(:,:,k)));
end

% play 3-DoF device orientation
L = 1; % coordinate axis length
A = [0 0 0 1; L 0 0 1; 0 0 0 1; 0 L 0 1; 0 0 0 1; 0 0 L 1].';
for k = 1:1:numData
    cla;
    figure(10);
    plot_inertial_frame(0.5); hold on; grid on; axis equal;
    T_gb = [R_gb(:,:,k), ones(3,1);
        zeros(1,3), 1];
    B = T_gb * A;
    plot3(B(1,1:2),B(2,1:2),B(3,1:2),'-r','LineWidth',1);   % x: red
    plot3(B(1,3:4),B(2,3:4),B(3,3:4),'-g','LineWidth',1);  % y: green
    plot3(B(1,5:6),B(2,5:6),B(3,5:6),'-b','LineWidth',1);  % z: blue
    refresh; pause(0.01);
    k
end

% plot roll/pitch/yaw of device orientation
figure(3);
subplot(3,1,1);
plot(deviceOrientationTime, rpy_gb(1,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(deviceOrientationTime) max(deviceOrientationTime) min(rpy_gb(1,:)) max(rpy_gb(1,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Roll [rad]','FontName','Times New Roman','FontSize',17);
subplot(3,1,2);
plot(deviceOrientationTime, rpy_gb(2,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(deviceOrientationTime) max(deviceOrientationTime) min(rpy_gb(2,:)) max(rpy_gb(2,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Pitch [rad]','FontName','Times New Roman','FontSize',17);
subplot(3,1,3);
plot(deviceOrientationTime, rpy_gb(3,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(deviceOrientationTime) max(deviceOrientationTime) min(rpy_gb(3,:)) max(rpy_gb(3,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Yaw [rad]','FontName','Times New Roman','FontSize',17);
set(gcf,'Units','pixels','Position',[100 200 1800 900]);  % modify figure


%% 3) calibrated magnetic field

% parsing calibrated magnetic field text
textFileDir = 'calibrated-magnetic-field.txt';
delimiter = ' ';
headerlinesIn = 0;
textMagnetData = importdata(textFileDir, delimiter, headerlinesIn);
magnetTime = textMagnetData(:,1).';
magnetTime = (magnetTime - magnetTime(1)) ./ 1000000000;
magnetData = textMagnetData(:,[2 3 4]).';

% plot calibrated magnetic field X-Y-Z
figure(4);
subplot(3,1,1);
plot(magnetTime, magnetData(1,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(magnetTime) max(magnetTime) min(magnetData(1,:)) max(magnetData(1,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('X [microT]','FontName','Times New Roman','FontSize',17);
subplot(3,1,2);
plot(magnetTime, magnetData(2,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(magnetTime) max(magnetTime) min(magnetData(2,:)) max(magnetData(2,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Y [microT]','FontName','Times New Roman','FontSize',17);
subplot(3,1,3);
plot(magnetTime, magnetData(3,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(magnetTime) max(magnetTime) min(magnetData(3,:)) max(magnetData(3,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Z [microT]','FontName','Times New Roman','FontSize',17);
set(gcf,'Units','pixels','Position',[100 200 1800 900]);  % modify figure


%% 4) raw acceleration

% parsing raw acceleration text
textFileDir = 'raw-acceleration.txt';
delimiter = ' ';
headerlinesIn = 0;
textRawAccelerationData = importdata(textFileDir, delimiter, headerlinesIn);
rawAccelTime = textRawAccelerationData(:,1).';
rawAccelTime = (rawAccelTime - rawAccelTime(1)) ./ 1000000000;
rawAccelData = textRawAccelerationData(:,[2 3 4]).';

% plot raw acceleration X-Y-Z
figure(5);
subplot(3,1,1);
plot(rawAccelTime, rawAccelData(1,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(rawAccelTime) max(rawAccelTime) min(rawAccelData(1,:)) max(rawAccelData(1,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('X [m/s-2]','FontName','Times New Roman','FontSize',17);
subplot(3,1,2);
plot(rawAccelTime, rawAccelData(2,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(rawAccelTime) max(rawAccelTime) min(rawAccelData(2,:)) max(rawAccelData(2,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Y [m/s-2]','FontName','Times New Roman','FontSize',17);
subplot(3,1,3);
plot(rawAccelTime, rawAccelData(3,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(rawAccelTime) max(rawAccelTime) min(rawAccelData(3,:)) max(rawAccelData(3,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Z [m/s-2]','FontName','Times New Roman','FontSize',17);
set(gcf,'Units','pixels','Position',[100 200 1800 900]);  % modify figure


%% 5) raw rotation rate

% parsing raw rotation rate text
textFileDir = 'raw-rotation-rate.txt';
delimiter = ' ';
headerlinesIn = 0;
textRawGyroData = importdata(textFileDir, delimiter, headerlinesIn);
rawGyroTime = textRawGyroData(:,1).';
rawGyroTime = (rawGyroTime - rawGyroTime(1)) ./ 1000000000;
rawGyroData = textRawGyroData(:,[2 3 4]).';

% plot raw rotation rate X-Y-Z
figure(6);
subplot(3,1,1);
plot(rawGyroTime, rawGyroData(1,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(rawGyroTime) max(rawGyroTime) min(rawGyroData(1,:)) max(rawGyroData(1,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('X [rad/s]','FontName','Times New Roman','FontSize',17);
subplot(3,1,2);
plot(rawGyroTime, rawGyroData(2,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(rawGyroTime) max(rawGyroTime) min(rawGyroData(2,:)) max(rawGyroData(2,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Y [rad/s]','FontName','Times New Roman','FontSize',17);
subplot(3,1,3);
plot(rawGyroTime, rawGyroData(3,:), 'm'); hold on; grid on; axis tight;
set(gcf,'color','w'); hold off;
axis([min(rawGyroTime) max(rawGyroTime) min(rawGyroData(3,:)) max(rawGyroData(3,:))]);
set(get(gcf,'CurrentAxes'),'FontName','Times New Roman','FontSize',17);
xlabel('Time [sec]','FontName','Times New Roman','FontSize',17);
ylabel('Z [rad/s]','FontName','Times New Roman','FontSize',17);
set(gcf,'Units','pixels','Position',[100 200 1800 900]);  % modify figure


