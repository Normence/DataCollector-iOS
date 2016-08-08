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
    @IBOutlet var mapTextField: UITextField!
    @IBOutlet var poseTextField: UITextField!
    @IBOutlet var traceTextField: UITextField!

    var recognizerOn = false
    var mapID = defaultMapID
    var poseID = defaultPoseID
    var traceID = defaultTraceID
    
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
            adjustStatusTextFormat(statusTextView)
            
            //start recognizer
        }
        else{
            NSLog("Stop Recognizer", self)
            recognizerOn = !recognizerOn
            mapTextField.enabled = true
            poseTextField.enabled = true
            traceTextField.enabled = true
            startButton.setTitle("START", forState: .Normal)
            
            //stop sensors
            
            statusTextView.text = "Status: STOP"
            adjustStatusTextFormat(statusTextView)
        }
    }
    
    func startRecognizer() {
        statusTextView.text = "Status: Initializing..."
        adjustStatusTextFormat(statusTextView)
        
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
