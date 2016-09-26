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
    
    enum motionStatus: Int {
        case MOVING = -1
        case IDLE, WALKING
    }
    
    var recognizerOn = false
    var mapID = defaultMapID
    var poseID = defaultPoseID
    var traceID = defaultTraceID
    var fileManager = NSFileManager.init()
    var dataFileHandle = NSFileHandle.init()
    var outputFileHandle = NSFileHandle.init()
    var datas: [[String]?]? = []
    var dataLen = 0
    var dataCount = 1
    var dataEnd = 0
    var timer = NSTimer.init()
    var τMax = defaultMaxτ
    var τMin = defaultMinτ
    var status = motionStatus.IDLE
    
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
            statusTextView.text = "Status: Starting..."
            
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
            outputFileHandle.closeFile()
            if timer.valid {
                timer.invalidate()
            }
            datas = []
            
            statusTextView.text = "Status: STOP"
            recognitionTextView.text = "STATUS"
        }
    }
    
    func startRecognizer() {
        statusTextView.text = "Status: Initializing..."
        
        //locate file
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentDirectory = paths[0]
        
        let dataPath = documentDirectory.stringByAppendingString("/parking\(mapID)pose\(poseID)trace\(traceID).txt")
        let outputPath = documentDirectory.stringByAppendingString("/parking\(mapID)pose\(poseID)trace\(traceID)(Output).txt")
        
        if fileManager.fileExistsAtPath(outputPath) {
            do{
                try fileManager.removeItemAtPath(outputPath)
                print("Remove file: " + outputPath)
            } catch _ as NSError {
                NSLog("Unable to remove file: " + outputPath, self)
            }
        }
        
        if fileManager.createFileAtPath(outputPath, contents: nil, attributes: nil) {
            print("Create file: " + outputPath)
        } else {
            print("Unable to create file: " + outputPath)
        }
        
        if let d = NSFileHandle.init(forReadingAtPath: dataPath) {
            dataFileHandle = d
            print("Reading file: " + dataPath)
        } else {
            NSLog("Fail to open file: " + dataPath, self)
            statusTextView.text = "Status: File not found"
            return
        }
        
        if let d = NSFileHandle.init(forWritingAtPath: outputPath){
            outputFileHandle = d
            print("Writing file: " + outputPath)
            let s = "Status index s MaxNac τ\n"
            outputFileHandle.writeData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
        } else {
            NSLog("Fail to open file: " + outputPath, self)
            statusTextView.text = "Status: File not found"
            return
        }
        
        //read data
        statusTextView.text = "Status: Recognizing..."
        let data = dataFileHandle.readDataToEndOfFile()
        let temp_data = String.init(data: data, encoding: NSUTF8StringEncoding)
        let temp_datas = temp_data?.componentsSeparatedByString("\n")
        
        for i in 0..<(temp_datas?.count)! {
            let temp_datas_i = temp_datas![i].componentsSeparatedByString(" ")
            datas?.insert(temp_datas_i, atIndex: i)
        }
        dataLen = (datas?.count)!
        dataCount = 1
        dataEnd = dataLen - defaultMaxτ
        
        //timer = NSTimer.scheduledTimerWithTimeInterval(dataUpdateInterval, target: self, selector: #selector(refreshUI(_:)), userInfo: nil, repeats: true)
        
        for _ in 1...dataEnd{
            motionRecognition()
        }
        
    }
    
    func motionRecognition() {
        if dataCount < dataEnd {
            print("dataCount: \(dataCount), dataLen: \(dataLen)， dataEnd: \(dataEnd)")
            
            let sd = calculateSD(datas, begin: dataCount, end: dataCount + Int(1.0 / dataUpdateInterval) - 1)  //50Hz sampling frequency with 50 samples per second
            
            var outputString = ""
            if sd < 0.01 {
                //idle
                status = .IDLE
                print("Motion Recognized as IDLE with index: \(dataCount), sd: \(sd)")
                outputString = "0, \(dataCount), \(sd)\n"
                τMax = defaultMaxτ
                τMin = defaultMinτ
            } else {
                //walking or moving
                //get the maximum Normalized Auto-Correlation and the corresponding τ
                var nacMax = 0.00
                var nacMax_τ = 0
                for τ in τMin...τMax {
                    let nac = calculateNAC(datas, begin: dataCount, end: dataCount + τ - 1)
                    if nac > nacMax {
                        nacMax = nac
                        nacMax_τ = τ
                    }
                }
                τMax = nacMax_τ + 10
                τMin = nacMax_τ - 10
                if τMin <= 0 {
                    τMax = defaultMaxτ
                    τMin = defaultMinτ
                }
                print("τmin: \(τMin), τmax: \(τMax)")
                
                if nacMax > 0.7 {
                    //WALKING
                    status = .WALKING
                    print("Motion Recognized as WALKING with index: \(dataCount), sd: \(sd), MAXNac: \(nacMax), τ: \(nacMax_τ)")
                    outputString = "1, \(dataCount), \(sd), \(nacMax), \(nacMax_τ)\n"
                } else {
                    //MOVING
                    status = .MOVING
                    print("Motion Recognized as MOVING with index: \(dataCount), sd: \(sd), MAXNac: \(nacMax), τ: \(nacMax_τ)")
                    outputString = "-1, \(dataCount), \(sd), \(nacMax), \(nacMax_τ)\n"
                    τMax = defaultMaxτ
                    τMin = defaultMinτ
                }
                
            }
            outputFileHandle.writeData(outputString.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            dataCount += 1
        } else{
            //finish
            NSLog("Finish", self)
            statusTextView.text = "Status: Finish"
        }
    }
    
    func calculateSD(datas: [[String]?]?, begin: Int, end: Int) -> Double {
        var stop: Int
        
        if end > (dataLen - 1) {
            stop = (dataLen - 1)
        } else {
            stop = end
        }
        
        let nums = (end - begin + 1)
        
        var avg = 0.00
        
        //get mean
        avg = calculateAvg(datas, begin: begin, end: end)
        
        //get Standard Deviation
        var sum = 0.00
        for i in begin...end {
            if i < dataLen{
                if !datas![i]!.isEmpty{
                    if datas![i]!.count == dataItemNumber {
                        let norm = sqrt(square(Double(datas![i]![1])!) + square(Double(datas![i]![2])!) + square(Double(datas![i]![3])!))
                        sum += square(norm - avg)
                    }
                }
            } else {
                sum += square(0 - avg)
            }
        }
        
        avg = sum / Double(nums)
        
        return sqrt(avg)
    }
    
    func square(x: Double) -> Double {
        return x * x
    }
    
    func calculateAvg(datas: [[String]?]?, begin: Int, end: Int) -> Double {
        var stop: Int
        
        if end > (dataLen - 1) {
            stop = dataLen - 1
        } else {
            stop = end
        }
        
        let nums = (end - begin + 1)
        
        var sum = 0.00
        
        //get sum
        for i in begin...stop {
            if i < dataLen{
                if !datas![i]!.isEmpty {
                    if datas![i]!.count == dataItemNumber {
                        sum += sqrt(square(Double(datas![i]![1])!) + square(Double(datas![i]![2])!) + square(Double(datas![i]![3])!))
                    }
                }
            }
        }
        
        let avg = sum / Double(nums)
        return avg
    }
    
    func calculateNAC(datas: [[String]?]?, begin: Int, end: Int) -> Double {  //{∑<k=0...k=τ-1> [(a(m+k)-μ(m,τ))·(a(m+k+τ)-μ(m+τ,τ))]}/τσ(m,τ)σ(m+τ,τ)
        
        let τ = (end - begin + 1)
        let μ_m_τ = calculateAvg(datas, begin: begin, end: end)
        let σ_m_τ = calculateSD(datas, begin: begin, end: end)
        var μ_m＋τ_τ: Double
        var σ_m＋τ_τ: Double
        
        if (begin + τ) >= dataLen {
            μ_m＋τ_τ = 0.00
            σ_m＋τ_τ = 0.00
        } else {
            μ_m＋τ_τ = calculateAvg(datas, begin: begin + τ, end: end + τ)
            σ_m＋τ_τ = calculateSD(datas, begin: begin + τ, end: end + τ)
        }
        
        
        var sum = 0.00
        
        for i in begin...end {
            var temp1 = 0.00
            var temp2 = 0.00
            
            if i < dataLen{
                if !datas![i]!.isEmpty {
                    if datas![i]!.count == dataItemNumber {
                        let norm = sqrt(square(Double(datas![i]![1])!) + square(Double(datas![i]![2])!) + square(Double(datas![i]![3])!))
                        temp1 += (norm - μ_m_τ)
                    }
                }
            } else {
                temp1 -= μ_m_τ
            }
            
            if (i + τ) < dataLen{
                if !datas![i+τ]!.isEmpty {
                    if datas![i+τ]!.count == dataItemNumber {
                        let norm = sqrt(square(Double(datas![i+τ]![1])!) + square(Double(datas![i+τ]![2])!) + square(Double(datas![i+τ]![3])!))
                        temp2 += (norm - μ_m＋τ_τ)
                    }
                }
            } else {
                temp2 -= μ_m＋τ_τ
            }
            
            sum += (temp1 * temp2)
        }
        
        let temp3 = (Double(τ) * σ_m_τ * σ_m＋τ_τ)
        
        var nac: Double
        if temp3 != 0 {
            nac = sum / temp3
        } else {
            nac = 0
        }
        
        return nac
    }
    
    func max(x: Double, y: Double, z: Double) -> Double {
        if x > y {
            if x > z {
                return x
            } else {
                return z
            }
        } else {
            if y > z {
                return y
            } else {
                return z
            }
        }
    }
    /////////////////
    
    func refreshUI(timer: NSTimer) {
        switch  status {
        case .IDLE:
            recognitionTextView.text = "IDLE"
        case .MOVING:
            recognitionTextView.text = "MOVING"
        case .WALKING:
            recognitionTextView.text = "WALKING"
        }
    }
    
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
            print("No map value, MapID changes to \(defaultMapID)")
            mapID = defaultMapID
            sender.text = String(mapID)
        }
        else{
            mapID = Int(sender.text!)!
            print("MapID changes to \(mapID)")
        }
        
        sender.resignFirstResponder()
        resumeView()
    }
    
    @IBAction func poseTextFieldEdited(sender: UITextField) {
        if((sender.text == nil)){
            print("No pose value, PoseID changes to \(defaultPoseID)")
            poseID = defaultPoseID
            sender.text = String(poseID)
        }
        else{
            poseID = Int(sender.text!)!
            print("PoseID changes to \(poseID)")
        }
        
        sender.resignFirstResponder()
        resumeView()
    }
    
    @IBAction func traceTextFieldEdited(sender: UITextField) {
        if((sender.text == nil)){
            print("No trace value, TraceID changes to \(defaultTraceID)")
            traceID = defaultTraceID
            sender.text = String(traceID)
        }
        else{
            traceID = Int(sender.text!)!
            print("TraceID changes to \(traceID)")
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
