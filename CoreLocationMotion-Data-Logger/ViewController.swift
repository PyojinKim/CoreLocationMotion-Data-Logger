//
//  ViewController.swift
//  CoreLocationMotion-Data-Logger
//
//  Created by kimpyojin on 29/05/2019.
//  Copyright © 2019 Pyojin Kim. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import os.log

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // cellphone screen UI outlet objects
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var horizontalAccuracyLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var buildingFloorLabel: UILabel!
    @IBOutlet weak var verticalAccuracyLabel: UILabel!
    
    @IBOutlet weak var rxLabel: UILabel!
    @IBOutlet weak var ryLabel: UILabel!
    @IBOutlet weak var rzLabel: UILabel!
    @IBOutlet weak var mxLabel: UILabel!
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var mzLabel: UILabel!
    
    @IBOutlet weak var axLabel: UILabel!
    @IBOutlet weak var ayLabel: UILabel!
    @IBOutlet weak var azLabel: UILabel!
    
    @IBOutlet weak var wxLabel: UILabel!
    @IBOutlet weak var wyLabel: UILabel!
    @IBOutlet weak var wzLabel: UILabel!
    
    @IBOutlet weak var stepCounterLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    
    // constants for collecting data
    let numSensor = 14
    let GYRO_TXT = 0
    let GYRO_UNCALIB_TXT = 1
    let ACCE_TXT = 2
    let LINACCE_TXT = 3
    let GRAVITY_TXT = 4
    let MAGNET_TXT = 5
    let MAGNET_UNCALIB_TXT = 6
    let GAME_RV_TXT = 7
    let GPS_TXT = 8
    let STEP_TXT = 9
    let HEADING_TXT = 10
    let HEIGHT_TXT = 11
    let PRESSURE_TXT = 12
    let BATTERY_TXT = 13
    
    let sampleFrequency: TimeInterval = 200
    let gravity: Double = 9.81
    let defaultValue: Double = 0.0
    var isRecording: Bool = false
    
    
    // various motion managers and queue instances
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let pedoMeter = CMPedometer()
    let altimeter = CMAltimeter()
    let customQueue: DispatchQueue = DispatchQueue(label: "pyojinkim.me")
    
    // variables for measuring time in iOS clock
    var recordingTimer: Timer = Timer()
    var batteryLevelTimer: Timer = Timer()
    var secondCounter: Int64 = 0 {
        didSet {
            statusLabel.text = interfaceIntTime(second: secondCounter)
        }
    }
    let mulSecondToNanoSecond: Double = 1000000000
    
    
    // text file input & output
    var fileHandlers = [FileHandle]()
    var fileURLs = [URL]()
    var fileNames: [String] = ["gyro.txt", "gyro_uncalib.txt", "acce.txt", "linacce.txt", "gravity.txt", "magnet.txt", "magnet_uncalib.txt", "game_rv.txt", "gps.txt", "step.txt", "heading.txt", "height.txt", "pressure.txt", "battery.txt"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // default device setting
        statusLabel.text = "Ready"
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // define Core Location manager setting
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // define Core Motion manager setting
        customQueue.async {
            self.startIMUUpdate()
            self.startPedometerUpdate()
            self.startAltimeterUpdate()
            self.startBatteryLevelUpdate()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        customQueue.sync {
            stopIMUUpdate()
        }
        pedoMeter.stopUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }
    
    
    // when the Start/Stop button is pressed
    @IBAction func startStopButtonPressed(_ sender: UIButton) {
        if (self.isRecording == false) {
            
            // start GPS/IMU data recording
            customQueue.async {
                if (self.createFiles()) {
                    DispatchQueue.main.async {
                        // reset timer
                        self.secondCounter = 0
                        self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) -> Void in
                            self.secondCounter += 1
                        })
                        
                        // update UI
                        self.startStopButton.setTitle("Stop", for: .normal)
                        
                        // make sure the screen won't lock
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                    self.isRecording = true
                } else {
                    self.errorMsg(msg: "Failed to create the file")
                    return
                }
            }
        } else {
            
            // stop recording and share the recorded text file
            if (recordingTimer.isValid) {
                recordingTimer.invalidate()
            }
            if (batteryLevelTimer.isValid) {
                batteryLevelTimer.invalidate()
            }
            
            customQueue.async {
                self.isRecording = false
                if (self.fileHandlers.count == self.numSensor) {
                    for handler in self.fileHandlers {
                        handler.closeFile()
                    }
                    DispatchQueue.main.async {
                        let activityVC = UIActivityViewController(activityItems: self.fileURLs, applicationActivities: nil)
                        self.present(activityVC, animated: true, completion: nil)
                    }
                }
            }
            
            // initialize UI on the screen
            self.latitudeLabel.text = String(format:"%.3f", self.defaultValue)
            self.longitudeLabel.text = String(format:"%.3f", self.defaultValue)
            self.horizontalAccuracyLabel.text = String(format:"%.3f", self.defaultValue)
            self.altitudeLabel.text = String(format:"%.2f", self.defaultValue)
            self.buildingFloorLabel.text = String(format:"%02df", self.defaultValue)
            self.verticalAccuracyLabel.text = String(format:"%.3f", self.defaultValue)
            
            self.rxLabel.text = String(format:"%.3f", self.defaultValue)
            self.ryLabel.text = String(format:"%.3f", self.defaultValue)
            self.rzLabel.text = String(format:"%.3f", self.defaultValue)
            self.mxLabel.text = String(format:"%.3f", self.defaultValue)
            self.myLabel.text = String(format:"%.3f", self.defaultValue)
            self.mzLabel.text = String(format:"%.3f", self.defaultValue)
            
            self.axLabel.text = String(format:"%.3f", self.defaultValue)
            self.ayLabel.text = String(format:"%.3f", self.defaultValue)
            self.azLabel.text = String(format:"%.3f", self.defaultValue)

            self.wxLabel.text = String(format:"%.3f", self.defaultValue)
            self.wyLabel.text = String(format:"%.3f", self.defaultValue)
            self.wzLabel.text = String(format:"%.3f", self.defaultValue)
            
            self.stepCounterLabel.text = String(format:"%04d", self.defaultValue)
            self.distanceLabel.text = String(format:"%.1f", self.defaultValue)
            
            self.startStopButton.setTitle("Start", for: .normal)
            self.statusLabel.text = "Ready"
            
            // resume screen lock
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    
    // define startUpdatingLocation() function
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // optional binding for safety
        if let latestLocation = manager.location {
            let timestamp = latestLocation.timestamp.timeIntervalSince1970 * self.mulSecondToNanoSecond
            let latitude = latestLocation.coordinate.latitude
            let longitude = latestLocation.coordinate.longitude
            let horizontalAccuracy = latestLocation.horizontalAccuracy
            let altitude = latestLocation.altitude
            let verticalAccuracy = latestLocation.verticalAccuracy
            var buildingFloor = -9
            if let temp = latestLocation.floor {
                buildingFloor = temp.level
            }
            
            // dispatch queue to display UI
            DispatchQueue.main.async {
                self.latitudeLabel.text = String(format:"%.3f", latitude)
                self.longitudeLabel.text = String(format:"%.3f", longitude)
                self.horizontalAccuracyLabel.text = String(format:"%.3f", horizontalAccuracy)
                self.altitudeLabel.text = String(format:"%.2f", altitude)
                self.verticalAccuracyLabel.text = String(format:"%.3f", verticalAccuracy)
                self.buildingFloorLabel.text = String(format:"%02d", buildingFloor)
            }
            
            // custom queue to save GPS location data
            self.customQueue.async {
                if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                    let locationData = String(format: "%.0f %.6f %.6f %.6f %.6f %.6f %.6f \n",
                                              timestamp,
                                              latitude,
                                              longitude,
                                              horizontalAccuracy,
                                              altitude,
                                              verticalAccuracy,
                                              buildingFloor)
                    if let locationDataToWrite = locationData.data(using: .utf8) {
                        self.fileHandlers[self.GPS_TXT].write(locationDataToWrite)
                    } else {
                        os_log("Failed to write data record", log: OSLog.default, type: .fault)
                    }
                }
            }
        }
    }
    
    
    // define didFailWithError function
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Error => \(error.localizedDescription)")
    }
    
    
    // define startIMUUpdate() function
    private func startIMUUpdate() {
        
        // define IMU update interval up to 200 Hz (in real, iOS can only support up to 100 Hz)
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleFrequency
        motionManager.showsDeviceMovementDisplay = true
        motionManager.accelerometerUpdateInterval = 1.0 / sampleFrequency
        motionManager.gyroUpdateInterval = 1.0 / sampleFrequency
        motionManager.magnetometerUpdateInterval = 1.0 / sampleFrequency
        
        
        // 1) update device motion
        if (!motionManager.isDeviceMotionActive) {
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: OperationQueue.main) { (motion: CMDeviceMotion?, error: Error?) in
                
                // optional binding for safety
                if let deviceMotion = motion {
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let timestamp = deviceMotion.timestamp * self.mulSecondToNanoSecond
                    let deviceOrientationRx = deviceMotion.attitude.pitch
                    let deviceOrientationRy = deviceMotion.attitude.roll
                    let deviceOrientationRz = deviceMotion.attitude.yaw
                    
                    let deviceOrientationQx = deviceMotion.attitude.quaternion.x
                    let deviceOrientationQy = deviceMotion.attitude.quaternion.y
                    let deviceOrientationQz = deviceMotion.attitude.quaternion.z
                    let deviceOrientationQw = deviceMotion.attitude.quaternion.w
                    
                    let processedGyroDataX = deviceMotion.rotationRate.x
                    let processedGyroDataY = deviceMotion.rotationRate.y
                    let processedGyroDataZ = deviceMotion.rotationRate.z
                    
                    let gravityGx = deviceMotion.gravity.x * self.gravity
                    let gravityGy = deviceMotion.gravity.y * self.gravity
                    let gravityGz = deviceMotion.gravity.z * self.gravity
                    
                    let userAccelDataX = deviceMotion.userAcceleration.x * self.gravity
                    let userAccelDataY = deviceMotion.userAcceleration.y * self.gravity
                    let userAccelDataZ = deviceMotion.userAcceleration.z * self.gravity
                    
                    let magneticFieldX = deviceMotion.magneticField.field.x
                    let magneticFieldY = deviceMotion.magneticField.field.y
                    let magneticFieldZ = deviceMotion.magneticField.field.z
                    
                    let deviceHeadingAngle = deviceMotion.heading
                    
                    // dispatch queue to display UI
                    DispatchQueue.main.async {
                        self.rxLabel.text = String(format:"%.3f", deviceOrientationRx)
                        self.ryLabel.text = String(format:"%.3f", deviceOrientationRy)
                        self.rzLabel.text = String(format:"%.3f", deviceOrientationRz)
                        
                        self.mxLabel.text = String(format:"%.3f", magneticFieldX)
                        self.myLabel.text = String(format:"%.3f", magneticFieldY)
                        self.mzLabel.text = String(format:"%.3f", magneticFieldZ)
                    }
                    
                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                            
                            // the device orientation expressed in the quaternion format
                            let attitudeData = String(format: "%.0f %.6f %.6f %.6f %.6f \n",
                                                      timestamp,
                                                      deviceOrientationQx,
                                                      deviceOrientationQy,
                                                      deviceOrientationQz,
                                                      deviceOrientationQw)
                            if let attitudeDataToWrite = attitudeData.data(using: .utf8) {
                                self.fileHandlers[self.GAME_RV_TXT].write(attitudeDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                            
                            // the unbiased rotation rate
                            let processedGyroData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                           timestamp,
                                                           processedGyroDataX,
                                                           processedGyroDataY,
                                                           processedGyroDataZ)
                            if let processedGyroDataToWrite = processedGyroData.data(using: .utf8) {
                                self.fileHandlers[self.GYRO_TXT].write(processedGyroDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                            
                            // the current gravity vector
                            let gravityData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                     timestamp,
                                                     gravityGx,
                                                     gravityGy,
                                                     gravityGz)
                            if let gravityDataToWrite = gravityData.data(using: .utf8) {
                                self.fileHandlers[self.GRAVITY_TXT].write(gravityDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                            
                            // the user-generated acceleration vector (without gravity)
                            let userAccelData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                       timestamp,
                                                       userAccelDataX,
                                                       userAccelDataY,
                                                       userAccelDataZ)
                            if let userAccelDataToWrite = userAccelData.data(using: .utf8) {
                                self.fileHandlers[self.LINACCE_TXT].write(userAccelDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                            
                            // the current magnetic field vector
                            let magneticData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                      timestamp,
                                                      magneticFieldX,
                                                      magneticFieldY,
                                                      magneticFieldZ)
                            if let magneticDataToWrite = magneticData.data(using: .utf8) {
                                self.fileHandlers[self.MAGNET_TXT].write(magneticDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                            
                            // the heading angle (degrees) relative to the reference frame
                            let headingAngleData = String(format: "%.0f %.6f \n",
                                                          timestamp,
                                                          deviceHeadingAngle)
                            if let headingAngleDataToWrite = headingAngleData.data(using: .utf8) {
                                self.fileHandlers[self.HEADING_TXT].write(headingAngleDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }
                }
            }
        }
        
        
        // 2) update raw acceleration value
        if (!motionManager.isAccelerometerActive) {
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (motion: CMAccelerometerData?, error: Error?) in
                
                // optional binding for safety
                if let accelerometerData = motion {
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let timestamp = accelerometerData.timestamp * self.mulSecondToNanoSecond
                    let rawAccelDataX = accelerometerData.acceleration.x * self.gravity
                    let rawAccelDataY = accelerometerData.acceleration.y * self.gravity
                    let rawAccelDataZ = accelerometerData.acceleration.z * self.gravity
                    
                    // dispatch queue to display UI
                    DispatchQueue.main.async {
                        self.axLabel.text = String(format:"%.3f", rawAccelDataX)
                        self.ayLabel.text = String(format:"%.3f", rawAccelDataY)
                        self.azLabel.text = String(format:"%.3f", rawAccelDataZ)
                    }
                    
                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                            let rawAccelData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                      timestamp,
                                                      rawAccelDataX,
                                                      rawAccelDataY,
                                                      rawAccelDataZ)
                            if let rawAccelDataToWrite = rawAccelData.data(using: .utf8) {
                                self.fileHandlers[self.ACCE_TXT].write(rawAccelDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }
                }
            }
        }
        
        
        // 3) update raw gyroscope value
        if (!motionManager.isGyroActive) {
            motionManager.startGyroUpdates(to: OperationQueue.main) { (motion: CMGyroData?, error: Error?) in
                
                // optional binding for safety
                if let gyroData = motion {
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let timestamp = gyroData.timestamp * self.mulSecondToNanoSecond
                    let rawGyroDataX = gyroData.rotationRate.x
                    let rawGyroDataY = gyroData.rotationRate.y
                    let rawGyroDataZ = gyroData.rotationRate.z
                    
                    // dispatch queue to display UI
                    DispatchQueue.main.async {
                        self.wxLabel.text = String(format:"%.3f", rawGyroDataX)
                        self.wyLabel.text = String(format:"%.3f", rawGyroDataY)
                        self.wzLabel.text = String(format:"%.3f", rawGyroDataZ)
                    }
                    
                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                            let rawGyroData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                     timestamp,
                                                     rawGyroDataX,
                                                     rawGyroDataY,
                                                     rawGyroDataZ)
                            if let rawGyroDataToWrite = rawGyroData.data(using: .utf8) {
                                self.fileHandlers[self.GYRO_UNCALIB_TXT].write(rawGyroDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }
                }
            }
        }
        
        
        // 4) update raw magnetometer data
        if (!motionManager.isMagnetometerActive) {
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (motion: CMMagnetometerData?, error: Error?) in
                
                // optional binding for safety
                if let magnetometerData = motion {
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let timestamp = magnetometerData.timestamp * self.mulSecondToNanoSecond
                    let rawMagnetDataX = magnetometerData.magneticField.x
                    let rawMagnetDataY = magnetometerData.magneticField.y
                    let rawMagnetDataZ = magnetometerData.magneticField.z
                    
                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                            let rawMagnetData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                       timestamp,
                                                       rawMagnetDataX,
                                                       rawMagnetDataY,
                                                       rawMagnetDataZ)
                            if let rawMagnetDataToWrite = rawMagnetData.data(using: .utf8) {
                                self.fileHandlers[self.MAGNET_UNCALIB_TXT].write(rawMagnetDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // define startPedometerUpdate() function
    private func startPedometerUpdate() {
        
        // check the step counter and distance are available
        if (CMPedometer.isStepCountingAvailable() && CMPedometer.isDistanceAvailable()) {
            pedoMeter.startUpdates(from: Date()) { (motion: CMPedometerData?, error: Error?) in
                
                // optional binding for safety
                if let pedometerData = motion {
                    let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let stepCounter = pedometerData.numberOfSteps.intValue
                    var distance: Double = -100
                    if let temp = pedometerData.distance {
                        distance = temp.doubleValue
                    }
                    
                    // dispatch queue to display UI
                    DispatchQueue.main.async {
                        self.stepCounterLabel.text = String(format:"%04d", stepCounter)
                        self.distanceLabel.text = String(format:"%.1f", distance)
                    }
                    
                    // custom queue to save pedometer data
                    self.customQueue.async {
                        if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                            let pedoData = String(format: "%.0f %04d %.3f \n",
                                                     timestamp,
                                                     stepCounter,
                                                     distance)
                            if let pedoDataToWrite = pedoData.data(using: .utf8) {
                                self.fileHandlers[self.STEP_TXT].write(pedoDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // define startAltimeterUpdate() function
    private func startAltimeterUpdate() {
        
        // check barometric sensor information are available
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (motion: CMAltitudeData?, error: Error?) in
                
                // optional binding for safety
                if let barometerData = motion {
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let timestamp = barometerData.timestamp * self.mulSecondToNanoSecond
                    let relativeAltitude = barometerData.relativeAltitude.doubleValue
                    let pressure = barometerData.pressure.doubleValue
                    
                    // custom queue to save barometric text data
                    self.customQueue.async {
                        if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                            
                            // the change in altitude (in meters) since the first reported event
                            let relativeAltitudeData = String(format: "%.0f %.6f \n",
                                                              timestamp,
                                                              relativeAltitude)
                            if let relativeAltitudeDataToWrite = relativeAltitudeData.data(using: .utf8) {
                                self.fileHandlers[self.HEIGHT_TXT].write(relativeAltitudeDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                            
                            // the recorded pressure (in kilopascals)
                            let pressureData = String(format: "%.0f %.6f \n",
                                                      timestamp,
                                                      pressure)
                            if let pressureDataToWrite = pressureData.data(using: .utf8) {
                                self.fileHandlers[self.PRESSURE_TXT].write(pressureDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // define startBatteryLevelUpdate() function
    private func startBatteryLevelUpdate() {
        DispatchQueue.main.async {
            self.batteryLevelTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) -> Void in
                
                let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                let batteryLevel = UIDevice.current.batteryLevel
                
                // custom queue to save battery level text data
                self.customQueue.async {
                    if ((self.fileHandlers.count == self.numSensor) && self.isRecording) {
                        
                        // the battery charge level for the device
                        let batteryLevelData = String(format: "%.0f %.6f \n",
                                                      timestamp,
                                                      batteryLevel)
                        if let batteryLevelDataToWrite = batteryLevelData.data(using: .utf8) {
                            self.fileHandlers[self.BATTERY_TXT].write(batteryLevelDataToWrite)
                        } else {
                            os_log("Failed to write data record", log: OSLog.default, type: .fault)
                        }
                    }
                }
            })
        }
    }
    
    
    private func stopIMUUpdate() {
        if (motionManager.isDeviceMotionActive) {
            motionManager.stopDeviceMotionUpdates()
        }
        if (motionManager.isAccelerometerActive) {
            motionManager.stopAccelerometerUpdates()
        }
        if (motionManager.isGyroActive) {
            motionManager.stopGyroUpdates()
        }
        if (motionManager.isMagnetometerActive) {
            motionManager.stopMagnetometerUpdates()
        }
    }
    
    
    // some useful functions
    private func errorMsg(msg: String) {
        DispatchQueue.main.async {
            let fileAlert = UIAlertController(title: "CoreLocationMotion-Data-Logger", message: msg, preferredStyle: .alert)
            fileAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(fileAlert, animated: true, completion: nil)
        }
    }
    
    
    private func createFiles() -> Bool {
        
        // initialize file handlers
        self.fileHandlers.removeAll()
        self.fileURLs.removeAll()
        
        // create each GPS/IMU sensor text files
        let startHeader = ""
        for i in 0...(self.numSensor - 1) {
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent(fileNames[i])
            self.fileURLs.append(url)
            
            // delete previous text files
            if (FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    os_log("cannot remove previous file", log:.default, type:.error)
                    return false
                }
            }
            
            // create new text files
            if (!FileManager.default.createFile(atPath: url.path, contents: startHeader.data(using: String.Encoding.utf8), attributes: nil)) {
                self.errorMsg(msg: "cannot create file \(self.fileNames[i])")
                return false
            }
            
            // assign new file handlers
            let fileHandle: FileHandle? = FileHandle(forWritingAtPath: url.path)
            if let handle = fileHandle {
                self.fileHandlers.append(handle)
            } else {
                return false
            }
        }
        
        // write current recording time information
        let timeHeader = "# Created at \(timeToString()) in Burnaby Canada \n"
        for i in 0...(self.numSensor - 1) {
            if let timeHeaderToWrite = timeHeader.data(using: .utf8) {
                self.fileHandlers[i].write(timeHeaderToWrite)
            } else {
                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                return false
            }
        }
        
        // return true if everything is alright
        return true
    }
}
