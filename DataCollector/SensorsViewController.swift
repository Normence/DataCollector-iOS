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

//parameters
//to be stored in another file probably
let defaultMapID = 5
let defaultPoseID = 1
let defaultTraceID = 1
let refreshTime = 50
/////

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
    var refreshCount = 0

    
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
    func adjustStatusTextFormat(textView: UITextView){
        textView.textColor = UIColor.grayColor()
        textView.font = UIFont.systemFontOfSize(10)
        textView.textAlignment = NSTextAlignment.Center
    }
    
    func startSensors(){
        //initialize sensors
        statusTextView.text = "Status: Initializing..."
        adjustStatusTextFormat(statusTextView)
        
        if motionManager.deviceMotionAvailable{
            NSLog("DeviceMotion Available", self)
            motionManager.deviceMotionUpdateInterval = 1.0/50.0
            motionManager.startDeviceMotionUpdates()
        }
        else{
            NSLog("DeviceMotion Unavailable", self)
        }
        if motionManager.gyroAvailable{
            NSLog("Gyro Available", self)
            motionManager.gyroUpdateInterval = 1.0/50.0
            motionManager.startGyroUpdates()
        }
        else{
            NSLog("Gyro Unavailable", self)
        }
        if motionManager.magnetometerAvailable{
            NSLog("Magnetometer Available", self)
            motionManager.magnetometerUpdateInterval = 1.0/50.0
            motionManager.startMagnetometerUpdates()
        }
        else{
            NSLog("Magnetometer Unavailable", self)
        }
        
        //create directories or files
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        
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
   
            //create data files
        let dataPath = currentDirectory.stringByAppendingString("/parking\(mapID)pose\(poseID)trace\(traceID).txt")
        fileManager.createFileAtPath(dataPath, contents: nil, attributes: nil)
        dataFileHandle = NSFileHandle.init(forWritingAtPath: dataPath)!
        
            //data head. Read the DataFormat.txt for detail
        let dataHead = "TimeStamp" + " accX accY accZ" + " gX gY gZ" + " a.roll a.pitch a.yaw" + " rateX rateY rateZ" + " h.true h.magn h.accu" + " fieldX fieldY fieldZ\n"
        dataFileHandle.writeData(dataHead.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        statusTextView.text = "Status: Collecting."
        adjustStatusTextFormat(statusTextView)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: #selector(getSensorsData(_:)), userInfo: nil, repeats: true)
    }
    
    //get sensors data and write into files and display on the screen
    func getSensorsData(timer: NSTimer){
        //acquire data
        let date = NSDate.init()
        let t_time = date.timeIntervalSince1970 * 1000
        let time = Double(t_time)
        
        var dataItem = "\(time)"
        dataItem += " \(motionManager.deviceMotion?.userAcceleration.x) \(motionManager.deviceMotion?.userAcceleration.y) \(motionManager.deviceMotion?.userAcceleration.z)"
        dataItem += " \(motionManager.deviceMotion?.gravity.x) \(motionManager.deviceMotion?.gravity.y) \(motionManager.deviceMotion?.gravity.z)"
        dataItem += " \(motionManager.deviceMotion?.attitude.roll) \(motionManager.deviceMotion?.attitude.pitch) \(motionManager.deviceMotion?.attitude.yaw)"
        dataItem += " \(motionManager.gyroData?.rotationRate.x) \(motionManager.gyroData?.rotationRate.y) \(motionManager.gyroData?.rotationRate.z)"
        dataItem += " \(locationManager.heading?.trueHeading) \(locationManager.heading?.magneticHeading)  \(locationManager.heading?.headingAccuracy)"
        dataItem += " \(motionManager.deviceMotion?.magneticField.field.x) \(motionManager.deviceMotion?.magneticField.field.y) \(motionManager.deviceMotion?.magneticField.field.z)\n"
        
        //write data into files
        dataFileHandle.writeData(dataItem.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        //representation control
        refreshCount += 1
        if refreshCount == refreshTime{
            NSLog(dataItem, self)
            if let t = statusTextView.text where t.hasSuffix("..."){
                statusTextView.text = "Status: Collecting."
                adjustStatusTextFormat(statusTextView)
            }
            else{
                let t = statusTextView.text + "."
                statusTextView.text = t
                adjustStatusTextFormat(statusTextView)
            }
            //display
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
            statusTextView.text = "Status: Starting..."
            adjustStatusTextFormat(statusTextView)
            
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
            timer.invalidate()
            dataFileHandle.closeFile()
            
            statusTextView.text = "Status: STOP"
            adjustStatusTextFormat(statusTextView)
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
