//
//  UIControlFunctions.swift
//  DataCollector
//
//  Created by Wenyu Luo on 16/8/8.
//  Copyright © 2016年 Wenyu Luo. All rights reserved.
//

import Foundation
import UIKit

func setStatusText(textView: UITextView, s: String){
    textView.text = s
    textView.textColor = UIColor.grayColor()
    textView.font = UIFont.systemFontOfSize(10)
    textView.textAlignment = NSTextAlignment.Center
}