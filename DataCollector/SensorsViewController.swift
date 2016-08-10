//
//  SensorsViewController.swift
//  DataCollector
//
//  Created by Wenyu Luo on 16/7/25.
//  Copyright © 2016年 Wenyu Luo. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

//TODO: data files management

class SensorsViewController: UIViewController {
    @IBOutlet var startButton: UIButton!
    @IBOutlet var mapTextField: UITextField!
    @IBOutlet var poseTextField: UITextField!
    @IBOutlet var traceTextField: UITextField!
    @IBOutlet var statusTextView: UITextView!
    
    var sensorsOn = false
    var mapID = defaultMapID
    var poseID = defaultPoseID
    var traceID = defaultTraceID
    var motionManager = CMMotionManager.init()
    var locationManager = CLLocationManager.init()
    var fileManager = NSFileManager.defaultManager()
    var dataFileHandle = NSFileHandle.init()
    var timer = NSTimer.init()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapTextField.text = String(mapID)
        poseTextField.text = String(poseID)
        traceTextField.text = String(traceID)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /* sensors control */
    func startSensors(){
        //initialize sensors
        setStatusText(statusTextView, s: "Status: Initializing...")
        
        if motionManager.deviceMotionAvailable{
            NSLog("DeviceMotion Available", self)
            motionManager.deviceMotionUpdateInterval = dataUpdateInterval
            motionManager.startDeviceMotionUpdates()
        }
        else{
            NSLog("DeviceMotion Unavailable", self)
        }
        if motionManager.gyroAvailable{
            NSLog("Gyro Available", self)
            motionManager.gyroUpdateInterval = dataUpdateInterval
            motionManager.startGyroUpdates()
        }
        else{
            NSLog("Gyro Unavailable", self)
        }
        if motionManager.magnetometerAvailable{
            NSLog("Magnetometer Available", self)
            motionManager.magnetometerUpdateInterval = dataUpdateInterval
            motionManager.startMagnetometerUpdates()
        }
        else{
            NSLog("Magnetometer Unavailable", self)
        }
        
        //create directories or files
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        
        /*
            //get current time
        let date = NSDate.init()
        let time = date.timeIntervalSince1970
        let currentDate = NSDate.init(timeIntervalSince1970: time)
        
        let dateFormatter = NSDateFormatter.init()
        dateFormatter.dateFormat = "yy_MM_dd"  //mm means minute, MM means month
        let currentTime = dateFormatter.stringFromDate(currentDate)
        NSLog("Current Time: \(currentTime)", self)
        
            //create directory /yy_mm_dd
        let currentDirectory = documentsDirectory.stringByAppendingString("/" + currentTime)
        NSLog("Current Directory: \(currentDirectory)", self)
        
        do{
            try fileManager.createDirectoryAtPath(currentDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch _ as NSError{
            NSLog("Fail to create current directory", self)
            return
        }
        NSLog("Successfully create current directory", self)
         */
   
            //create data files
        let dataPath = documentsDirectory.stringByAppendingString("/parking\(mapID)pose\(poseID)trace\(traceID).txt")
        fileManager.createFileAtPath(dataPath, contents: nil, attributes: nil)
        dataFileHandle = NSFileHandle.init(forWritingAtPath: dataPath)!
        
            //data head. Read the DataFormat.txt for detail
        let dataHead = "TimeStamp" + " accX accY accZ" + " gX gY gZ" + " a.roll a.pitch a.yaw" + " rateX rateY rateZ" + " h.true h.magn h.accu" + " fieldX fieldY fieldZ\n"
        dataFileHandle.writeData(dataHead.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        setStatusText(statusTextView, s: "Status: Collecting.")
        timer = NSTimer.scheduledTimerWithTimeInterval(dataUpdateInterval, target: self, selector: #selector(getSensorsData(_:)), userInfo: nil, repeats: true)
    }
    
    //get sensors data and write into files and display on the screen
    func getSensorsData(timer: NSTimer){
        //acquire data
        let date = NSDate.init()
        let t_time = date.timeIntervalSince1970 * 1000
        let time = Double(t_time)
        
        var dataItem = "\(time)"
        
        if let t = motionManager.deviceMotion?.userAcceleration.x {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.userAcceleration.y {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.userAcceleration.z {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.gravity.x {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.gravity.y {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.gravity.z {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.attitude.roll {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.attitude.pitch {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.attitude.yaw {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.gyroData?.rotationRate.x {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.gyroData?.rotationRate.y {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.gyroData?.rotationRate.z {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.magneticField.field.x {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.magneticField.field.y {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        if let t = motionManager.deviceMotion?.magneticField.field.z {
            dataItem = dataItem + " " + String(t)
        } else {
            dataItem = dataItem + " 0.000"
        }
        
        dataItem += "\n"
        
        //write data into files
        dataFileHandle.writeData(dataItem.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        //representation control
        refreshCount += 1
        if refreshCount == refreshTime{
            NSLog(dataItem, self)
            if let t = statusTextView.text where t.hasSuffix("..."){
                setStatusText(statusTextView, s: "Status: Collecting.")
            }
            else{
                let t = statusTextView.text + "."
                setStatusText(statusTextView, s: t)
            }
            //TODO: display
        }
        refreshCount %= refreshTime
    }
    
    @IBAction func sensorsButtonTouched(sender: UIButton) {
        if !sensorsOn {
            NSLog("Start Sensors", self)
            sensorsOn = !sensorsOn
            mapTextField.enabled = false
            poseTextField.enabled = false
            traceTextField.enabled = false
            startButton.setTitle("STOP", forState: .Normal)
            setStatusText(statusTextView, s: "Status: Starting...")
            
            //start sensors
            startSensors()
        }
        else{
            NSLog("Stop Sensors", self)
            sensorsOn = !sensorsOn
            mapTextField.enabled = true
            poseTextField.enabled = true
            traceTextField.enabled = true
            startButton.setTitle("START", forState: .Normal)
            
            traceID += 1
            traceTextField.text = String(traceID)
            
            //stop sensors
            timer.invalidate()
            dataFileHandle.closeFile()
            motionManager.stopGyroUpdates()
            motionManager.stopDeviceMotionUpdates()
            motionManager.stopMagnetometerUpdates()
            
            setStatusText(statusTextView, s: "Status: STOP")
        }
    }
    //////////////

    /* Map, Pose, Trace TextField Control */
    //上移视图，使键盘不至覆盖TextField
    func raiseView(){
        let animationDuration: NSTimeInterval = 0.30
        UIView.beginAnimations("ResizeForKeyboard", context: nil)
        UIView.setAnimationDuration(animationDuration)
        let width = self.view.frame.width
        let height = self.view.frame.height
        //视图沿y轴上移取负值，根据情况而定
        let rect = CGRectMake(0.00, -200, width, height)
        self.view.frame = rect
        UIView.commitAnimations()
    }
    
    //恢复视图
    func resumeView(){
        let animationDuration: NSTimeInterval = 0.30
        UIView.beginAnimations("ResizeForKeyboard", context: nil)
        UIView.setAnimationDuration(animationDuration)
        let width = self.view.frame.width
        let height = self.view.frame.height
        //视图沿y轴上移取负值，根据情况而定
        let rect = CGRectMake(0.00, 0.00, width, height)
        self.view.frame = rect
        UIView.commitAnimations()
    }

    @IBAction func mapTextFieldBeginEdit(sender: UITextField) {
        raiseView()
    }
    
    @IBAction func poseTextFieldBeginEdit(sender: UITextField) {
        raiseView()
    }
    
    @IBAction func traceTextFieldBeginEdit(sender: UITextField) {
        raiseView()
    }
    
    @IBAction func mapTextFieldEdited(sender: UITextField) {
        if((sender.text == nil)){
            NSLog("No map value, MapID changes to \(defaultMapID)", self)
            mapID = defaultMapID
            sender.text = String(mapID)
        }
        else{
            mapID = Int(sender.text!)!
            NSLog("MapID changes to \(mapID)", self)
        }
        
        sender.resignFirstResponder()
        resumeView()
    }
    
    @IBAction func poseTextFieldEdited(sender: UITextField) {
        if((sender.text == nil)){
            NSLog("No pose value, PoseID changes to \(defaultPoseID)", self)
            poseID = defaultPoseID
            sender.text = String(poseID)
        }
        else{
            poseID = Int(sender.text!)!
            NSLog("PoseID changes to \(poseID)", self)
        }
        
        sender.resignFirstResponder()
        resumeView()
    }
    
    @IBAction func traceTextFieldEdited(sender: UITextField) {
        if((sender.text == nil)){
            NSLog("No trace value, TraceID changes to \(defaultTraceID)", self)
            traceID = defaultTraceID
            sender.text = String(traceID)
        }
        else{
            traceID = Int(sender.text!)!
            NSLog("TraceID changes to \(traceID)", self)
        }
        
        sender.resignFirstResponder()
        resumeView()
    }
    ///////////

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
