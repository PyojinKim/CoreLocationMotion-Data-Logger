

%% compare unbiased vs raw gyro data (rotation rate)

temp = unbiasedGyroData - rawGyroData;
figure;
plot(temp(3,:));


for k = 1:size(temp,2)
    temptemp(k) = norm(temp(:,k));
end

figure;
plot(temptemp);


%%