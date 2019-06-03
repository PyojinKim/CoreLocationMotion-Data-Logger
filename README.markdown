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


## Output Format ##

I have chosen the following output formats, but they are easy to modify if you find something else more convenient.

* CLLocation (GPS-location.txt): `timestamp, latitude, longitude, horizontalAccuracy, altitude, buildingFloor, verticalAccuracy \n`
* CMDeviceMotion (device-orientation.txt): `timestamp, quaternion_x, quaternion_y, quaternion_z, quaternion_w \n`
* CMDeviceMotion (calibrated-magnetic-field.txt): `timestamp, magnetic_x, magnetic_y, magnetic_z \n`
* CMAccelerometerData (raw-acceleration.txt): `timestamp, acceleration_x, acceleration_y, acceleration_z \n`
* CMGyroData (raw-rotation-rate.txt): `timestamp, gyro_x, gyro_y, gyro_z \n`
* CMPedometerData (pedometer.txt): `timestamp, step count, distance \n`

There are alternative representations of the attitude (roll/pitch/yaw, quaternions, rotation matrix).
You will have to modify the source code if you prefer logging one of those instead of quaternion format.


## Offline Matlab Visualization ##

The ability to experiment with different algorithms to process the IMU data is the reason that I created this project in the first place. I've been working with SciPy/NumPy quite a bit these days as a beautiful, truly object oriented, free, and open source alternative to MATLAB. I've included an example script that you can use to parse and visualize the data that comes from CoreMotion Data Logger. Look under the Visualization directory to check it out. 

If you have the necessary packages installed (I don't remember what comes with Python these days), you can run the script by typing the following in your terminal:

    python exampleVisualizer.py

Here's one of the figures produced by the script:

![Data visualization](https://github.com/pokeefe/CoreMotion-Data-Logger/raw/master/Visualization/rotationRate.png)
