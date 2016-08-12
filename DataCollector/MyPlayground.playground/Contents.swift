//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

print(str)

var datas: [[String]?]?

let str2 = "ABC DEF GHI\nIHG FED CBA"

let temp_str = str2.componentsSeparatedByString("\n")

print(temp_str[0])
print(temp_str[1])

temp_str.count

datas = []
datas?.count

for i in 0..<temp_str.count {
    let temp_str2 = temp_str[i].componentsSeparatedByString(" ")
    datas?.insert(temp_str2, atIndex: i)
}

datas

datas?.count

