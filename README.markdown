# Core Location Motion Data Logger #

This is a simple application to allow the easy capture of GPS/IMU data on iOS devices for offline use.
I wanted to play around with data from GPS and IMU with Core Location and Core Motion frameworks in Swift 5.0 for iPhone Xs.

![Core Location Motion Data Logger](https://github.com/PyojinKim/CoreLocationMotion-Data-Logger/blob/master/screenshot.png)

The aspects of the IMU that you can log follow directly from the Core Motion documentation provided by Apple.
For more details, see the Core Motion documentation [here](https://developer.apple.com/documentation/coremotion).


## Usage Notes ##

The txt files are produced automatically after pressing Stop button.
This Xcode project is written under Xcode Version 10.2.1 (10E1001) for iOS 12.2.
It doesn't currently check for sensor availability before logging.


## Reference Frames and Device Attitude ##

In the global (inertial or reference) frame in Core Motion, +Z axis is vertical (up) and the X axis points toward magnetic north: [here](https://developer.apple.com/documentation/coremotion/getting_processed_device-motion_data/understanding_reference_frames_and_device_attitude).
Y axis is determined based on the Z- and X-axes using the right hand rule.
The device frame is attached as shown in the above figure: [here](https://developer.apple.com/documentation/coremotion/getting_raw_gyroscope_events).


## Output Format ##

I have chosen the following output formats, but they are easy to modify if you find something else more convenient.

* CLLocation (gps.txt): `timestamp, latitude, longitude, horizontalAccuracy, altitude, buildingFloor, verticalAccuracy \n`
* CMDeviceMotion (game_rv.txt): `timestamp, quaternion_x, quaternion_y, quaternion_z, quaternion_w \n`
* CMDeviceMotion (gyro.txt): `timestamp, gyro_x, gyro_y, gyro_z \n`
* CMDeviceMotion (gravity.txt): `timestamp, gravity_x, gravity_y, gravity_z \n`
* CMDeviceMotion (linacce.txt): `timestamp, user_acceleration_x, user_acceleration_y, user_acceleration_z \n`
* CMDeviceMotion (magnet.txt): `timestamp, magnetic_x, magnetic_y, magnetic_z \n`
* CMDeviceMotion (heading.txt): `timestamp, heading_angle \n`
* CMAccelerometerData (acce.txt): `timestamp, acceleration_x, acceleration_y, acceleration_z \n`
* CMGyroData (gyro_uncalib.txt): `timestamp, gyro_x, gyro_y, gyro_z \n`
* CMMagnetometerData (magnet_uncalib.txt): `timestamp, magnetic_x, magnetic_y, magnetic_z \n`
* CMPedometerData (step.txt): `timestamp, step count, distance \n`
* CMAltitudeData (height.txt): `timestamp, relative_altitude \n`
* CMAltitudeData (pressure.txt): `timestamp, pressure \n`
* UIDevice (battery.txt): `timestamp, battery_level \n`

There are alternative representations of the attitude (roll/pitch/yaw, quaternions, rotation matrix).
You will have to modify the source code if you prefer logging one of those instead of quaternion format.


## Offline Matlab Visualization ##

The ability to experiment with different algorithms to process the IMU data is the reason that I created this project in the first place.
I have included an example script that you can use to parse and visualize the data that comes from Core Location & Core Motion Data Logger.
Look under the Visualization directory to check it out.
You can run the script by typing the following in your terminal:

    run main_script.m

Here's one of the figures produced by the Matlab script:

![Data visualization](https://github.com/PyojinKim/CoreLocationMotion-Data-Logger/blob/master/data_visualization.png)
