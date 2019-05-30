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
    let numSensor = 6
    let GPS_LOCATION = 0
    let DEVICE_ORIENTATION = 1
    let IMU_ACCELEROMETER = 2
    let IMU_GYROSCOPE = 3
    let IMU_MAGNETOMETER = 4
    let PEDOMETER = 5
    
    let sampleFrequency: TimeInterval = 200
    let gravity: Double = 9.81
    let defaultValue: Double = 0.0
    var isRecording: Bool = false
    
    
    // various motion managers and queue instances
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let pedoMeter = CMPedometer()
    let customQueue: DispatchQueue = DispatchQueue(label: "pyojinkim.me")
    
    // variables for measuring time in iOS clock
    var recordingTimer: Timer = Timer()
    var secondCounter: Int64 = 0 {
        didSet {
            statusLabel.text = interfaceIntTime(second: secondCounter)
        }
    }
    let mulSecondToNanoSecond: Double = 1000000000
    
    
    // text file input & output
    var fileHandlers = [FileHandle]()
    var fileURLs = [URL]()
    var fileNames: [String] = ["location", "orientation.txt", "acceleration.txt"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // change status text to "Ready"
        statusLabel.text = "Ready"
        
        // define Core Location manager setting
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        
        // define Core Motion manager setting
        customQueue.async {
            self.startIMUUpdate()
            self.startPedometerUpdate()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        customQueue.sync {
            stopIMUUpdate()
        }
    }
    
    
    @IBAction func startStopButtonPressed(_ sender: UIButton) {
        
    }
    
    
    // didUpdateLocations method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // optional binding for safety
        if let latestLocation = manager.location {
            
            // dispatch queue to display UI
            DispatchQueue.main.async {
                self.latitudeLabel.text = String(format:"%.3f", latestLocation.coordinate.latitude)
                self.longitudeLabel.text = String(format:"%.3f", latestLocation.coordinate.longitude)
                self.horizontalAccuracyLabel.text = String(format:"%.3f", latestLocation.horizontalAccuracy)
                self.altitudeLabel.text = String(format:"%.2f", latestLocation.altitude)
                self.verticalAccuracyLabel.text = String(format:"%.3f", latestLocation.verticalAccuracy)
                if let buildingFloor = latestLocation.floor {
                    self.buildingFloorLabel.text = String(format:"%02d", buildingFloor.level)
                } else {
                    self.buildingFloorLabel.text = "nil"
                }
            }
            
            // custom queue to save GPS location data
            print("latestLocation.timestamp = \(latestLocation.timestamp.timeIntervalSince1970 * self.mulSecondToNanoSecond)")
            print("longitude = \(latestLocation.coordinate.longitude), latitude = \(latestLocation.coordinate.latitude)")
        }
    }
    
    
    // didFailWithError method
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Error => \(error.localizedDescription)")
    }
    
    
    private func startIMUUpdate() {
        
        // define IMU update interval up to 200 Hz
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleFrequency
        motionManager.accelerometerUpdateInterval = 1.0 / sampleFrequency
        motionManager.gyroUpdateInterval = 1.0 / sampleFrequency
        motionManager.magnetometerUpdateInterval = 1.0 / sampleFrequency
        
        
        // 1) update device motion
        if (!motionManager.isDeviceMotionActive) {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion: CMDeviceMotion?, error: Error?) in
                
                // optional binding for safety
                if let deviceMotion = motion {
                    
                    // dispatch queue to display UI
                    DispatchQueue.main.async {
                        self.rxLabel.text = String(format:"%.3f", deviceMotion.attitude.roll)
                        self.ryLabel.text = String(format:"%.3f", deviceMotion.attitude.yaw)
                        self.rzLabel.text = String(format:"%.3f", deviceMotion.attitude.pitch)
                        
                        self.mxLabel.text = String(format:"%.3f", deviceMotion.magneticField.field.x)
                        self.myLabel.text = String(format:"%.3f", deviceMotion.magneticField.field.y)
                        self.mzLabel.text = String(format:"%.3f", deviceMotion.magneticField.field.z)
                    }
                    
                    
                    // custom queue to save IMU text data
                    /*self.customQueue.async {
                        if (self.fileHandlers.count == self.numSensor && self.isRecording) {
                            
                            // Note that the device orientation is expressed in the quaternion form
                            let attitudeData = String(format: "%.0f %.6f %.6f %.6f %.6f \n",
                                                      Date().timeIntervalSince1970 * self.mulSecondToNanoSecond, // timestamp
                                                      deviceMotion.attitude.quaternion.x,                        // orientation in x
                                                      deviceMotion.attitude.quaternion.y,                        // orientation in y
                                                      deviceMotion.attitude.quaternion.z,                        // orientation in z
                                                      deviceMotion.attitude.quaternion.w)                        // orientation in w
                            if let attitudeDataToWrite = attitudeData.data(using: .utf8) {
                                self.fileHandlers[self.DEVICE_ORIENTATION].write(attitudeDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }*/
                }
            }
        }
        
        
        // 2) update raw acceleration value
        if (!motionManager.isAccelerometerActive) {
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (motion: CMAccelerometerData?, error: Error?) in
                
                // optional binding for safety
                if let accelerometerData = motion {
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
                    /*self.customQueue.async {
                        if (self.fileHandlers.count == self.numSensor && self.isRecording) {
                            let rawAccelData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                      Date().timeIntervalSince1970 * self.mulSecondToNanoSecond, // timestamp
                                                      rawAccelDataX,                                             // raw acceleration in x
                                                      rawAccelDataY,                                             // raw acceleration in y
                                                      rawAccelDataZ)                                             // raw acceleration in z
                            if let rawAccelDataToWrite = rawAccelData.data(using: .utf8) {
                                self.fileHandlers[self.IMU_ACCELEROMETER].write(rawAccelDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }*/
                }
            }
        }
        
        
        // 3) update raw gyroscope value
        if (!motionManager.isGyroActive) {
            motionManager.startGyroUpdates(to: OperationQueue.main) { (motion: CMGyroData?, error: Error?) in
                
                // optional binding for safety
                if let gyroData = motion {
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
                    /*self.customQueue.async {
                        if (self.fileHandlers.count == self.numSensor && self.isRecording) {
                            let rawGyroData = String(format: "%.0f %.6f %.6f %.6f \n",
                                                     Date().timeIntervalSince1970 * self.mulSecondToNanoSecond, // timestamp
                                                     rawGyroDataX,                                              // raw rotation rate in x
                                                     rawGyroDataY,                                              // raw rotation rate in y
                                                     rawGyroDataZ)                                              // raw rotation rate in z
                            if let rawGyroDataToWrite = rawGyroData.data(using: .utf8) {
                                self.fileHandlers[self.IMU_GYROSCOPE].write(rawGyroDataToWrite)
                            } else {
                                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                            }
                        }
                    }*/
                }
            }
        }
    }
    
    
    private func startPedometerUpdate() {
        
        // check the step counter and distance are available
        if (CMPedometer.isStepCountingAvailable() && CMPedometer.isDistanceAvailable()) {
            pedoMeter.startUpdates(from: Date()) { (motion: CMPedometerData?, error: Error?) in
                
                // optional binding for safety
                if let pedometerData = motion {
                    
                    // dispatch queue to display UI
                    DispatchQueue.main.async {
                        self.stepCounterLabel.text = String(format:"%04d", pedometerData.numberOfSteps.intValue)
                        if let distance = pedometerData.distance {
                            self.distanceLabel.text = String(format:"%.1f", distance.doubleValue)
                        } else {
                            self.distanceLabel.text = "nil"
                        }
                    }
                    
                    // custom queue to save GPS location data
                    print("Step: \(pedometerData.numberOfSteps)")
                    print("Distance: \(pedometerData.distance)")
                }
            }
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
    
    
    private func errorMsg(msg: String) {
        DispatchQueue.main.async {
            let fileAlert = UIAlertController(title: "IMURecorder", message: msg, preferredStyle: .alert)
            fileAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(fileAlert, animated: true, completion: nil)
        }
    }
}

