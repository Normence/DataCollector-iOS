//
//  RecognizerViewController.swift
//  DataCollector
//
//  Created by Wenyu Luo on 16/8/8.
//  Copyright © 2016年 Wenyu Luo. All rights reserved.
//

import UIKit

class RecognizerViewController: UIViewController {
    @IBOutlet var startButton: UIButton!
    @IBOutlet var statusTextView: UITextView!
    @IBOutlet var recognitionTextView: UITextView!
    @IBOutlet var mapTextField: UITextField!
    @IBOutlet var poseTextField: UITextField!
    @IBOutlet var traceTextField: UITextField!

    var recognizerOn = false
    var mapID = defaultMapID
    var poseID = defaultPoseID
    var traceID = defaultTraceID
    var dataFileHandle = NSFileHandle.init()
    var datas: [String]?
    var dataLen = 0
    var dataCount = 1
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
    
    ///////////
    
    /* Reconizer Control */
    @IBAction func startButtonTouched(sender: UIButton) {
        if !recognizerOn {
            NSLog("Start Recognizer", self)
            recognizerOn = !recognizerOn
            mapTextField.enabled = false
            poseTextField.enabled = false
            traceTextField.enabled = false
            startButton.setTitle("STOP", forState: .Normal)
            setStatusText(statusTextView, s: "Status: Starting...")
            
            //start recognizer
            startRecognizer()
        }
        else{
            NSLog("Stop Recognizer", self)
            recognizerOn = !recognizerOn
            mapTextField.enabled = true
            poseTextField.enabled = true
            traceTextField.enabled = true
            startButton.setTitle("START", forState: .Normal)
            
            //stop recognizer
            dataFileHandle.closeFile()
            if timer.valid {
                timer.invalidate()
            }
            
            setStatusText(statusTextView, s: "Status: STOP")
            recognitionTextView.text = "STATUS"
        }
    }
    
    func startRecognizer() {
        setStatusText(statusTextView, s: "Status: Initializing...")
        
        //locate file
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentDirectory = paths[0]
        
        let dataPath = documentDirectory.stringByAppendingString("/parking\(mapID)pose\(poseID)trace\(traceID).txt")
        
        if let d = NSFileHandle.init(forReadingAtPath: dataPath) {
            dataFileHandle = d
            NSLog("Reading file: " + dataPath, self)
        } else {
            NSLog("Fail to open file: " + dataPath, self)
            setStatusText(statusTextView, s: "Status: File not found")
            return
        }
        
        //read data
        setStatusText(statusTextView, s: "Status: Recognizing...")
        let data = dataFileHandle.readDataToEndOfFile()
        let temp_data = String.init(data: data, encoding: NSUTF8StringEncoding)
        datas = temp_data?.componentsSeparatedByString("\n")
        dataLen = (datas?.count)!
        dataCount = 1
        
        timer = NSTimer.scheduledTimerWithTimeInterval(dataUpdateInterval, target: self, selector: #selector(motionRecognition(_:)), userInfo: nil, repeats: true)
    }
    
    func motionRecognition(timer: NSTimer) {
        if dataCount < dataLen {
            let sd = calculateSD(datas, begin: dataCount, end: dataCount + 49)  //50Hz sampling frequency with 50 samples per second
            
            if sd.x <= 0.01 && sd.y <= 0.01 && sd.z <= 0.01 {
                //idle
                recognitionTextView.text = "IDLE"
                NSLog("Motion Recognized as IDLE with sd.x: \(sd.x) sd.y: \(sd.y) sd.z: \(sd.z)", self)
            } else {
                //walking or moving
                recognitionTextView.text = "WALKING"
                NSLog("Motion Recognized as WALKING with sd.x: \(sd.x) sd.y: \(sd.y) sd.z: \(sd.z)", self)
            }
            dataCount += 1
        } else{
            //finish
            NSLog("Finish", self)
            setStatusText(statusTextView, s: "Status: Finish")
            if timer.valid {
                timer.invalidate()
            }
        }
    }
    
    struct SD {  //Standard Deviation
        var x, y, z: Double
    }
    
    func calculateSD(datas: [String]?, begin: Int, end: Int) -> SD {
        var stop: Int
        
        if end > ((datas?.count)! - 1) {
            stop = (datas?.count)! - 1
        } else {
            stop = end
        }
        
        let nums = (stop - begin + 1)
        
        var sum_x = 0.00
        var sum_y = 0.00
        var sum_z = 0.00
        var avg_x = 0.00
        var avg_y = 0.00
        var avg_z = 0.00
        
        //get sum
        for i in begin...stop {
            if !datas![i].isEmpty {
                let temp_data = datas![i].componentsSeparatedByString(" ")
                if temp_data.count == dataItemNumber {
                    if let ax = Double(temp_data[1]){
                        sum_x += ax
                    }
                    if let ay = Double(temp_data[2]){
                        sum_y += ay
                    }
                    if let az = Double(temp_data[3]){
                        sum_z += az
                    }
                }
            }
        }
        
        //get mean
        avg_x = sum_x / Double(nums)
        avg_y = sum_y / Double(nums)
        avg_z = sum_z / Double(nums)
        
        //get Standard Deviation
        sum_x = 0.00
        sum_y = 0.00
        sum_z = 0.00
        for i in begin...stop {
            if !datas![i].isEmpty{
                let temp_data = datas![i].componentsSeparatedByString(" ")
                if temp_data.count == dataItemNumber {
                    if let ax = Double(temp_data[1]){
                        sum_x += square(ax - avg_x)
                    }
                    if let ay = Double(temp_data[2]){
                        sum_y += square(ay - avg_y)
                    }
                    if let az = Double(temp_data[3]){
                        sum_z += square(az - avg_z)
                    }
                }
            }
        }
        
        avg_x = sum_x / Double(nums)
        avg_y = sum_y / Double(nums)
        avg_z = sum_z / Double(nums)
        
        var sd: SD = SD.init(x: 0, y: 0, z: 0)
        sd.x = sqrt(avg_x)
        sd.y = sqrt(avg_y)
        sd.z = sqrt(avg_z)
        
        return sd
    }
    
    func square(x: Double) -> Double {
        return x * x
    }
    /////////////////
    
    
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
