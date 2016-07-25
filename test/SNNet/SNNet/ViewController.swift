//
//  ViewController.swift
//  SNNet
//
//  Created by satoshi on 7/25/16.
//  Copyright © 2016 Satoshi Nakajima. All rights reserved.
//

import UIKit

private func MyLog(text:String, level:Int = 1) {
    let s_verbosLevel = 0
    if level <= s_verbosLevel {
        print(text)
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        runTest()
    }
    
    @IBAction func runTest() {
        testGoogle()
        testLocal()
    }
    
    func testLocal() {
        var errorCount = 0
        let serviceGroup = dispatch_group_create()
        
        dispatch_group_enter(serviceGroup)
        SNNet.apiRoot = NSURL(string:"http://localhost:3000")!
        SNNet.get("/webhp", params: [ "q":"hello world" ]) { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("Local Search Faied", level: 0)
                errorCount += 1
            } else {
                MyLog("Local Search Succeeded", level: 1)
            }
        }
        dispatch_group_enter(serviceGroup)
        SNNet.get("/tobefailed") { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let error = err {
                if let netError = err as? SNNetError where netError.res.statusCode == 404 {
                    MyLog("Local Invalid Search Failed as Expected", level: 1)
                } else {
                    MyLog("Local Invalid Search Failed With an Unexpected error: \(error)", level: 0)
                }
            } else {
                MyLog("Local Invalid Search Succeeded Unexpectedly", level: 0)
                errorCount += 1
            }
        }
        
        dispatch_group_notify(serviceGroup, dispatch_get_main_queue()) {
            if errorCount > 0 {
                print("Local: Complete with error count = ", errorCount)
            } else {
                print("Local: Complete")
            }
        }
    }

    func testGoogle() {
        var errorCount = 0
        let serviceGroup = dispatch_group_create()
        
        dispatch_group_enter(serviceGroup)
        SNNet.get("https://www.google.com/webhp", params: [ "q":"hello world" ]) { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("Google Search Faied", level: 0)
                errorCount += 1
            } else {
                MyLog("Google Search Succeeded", level: 1)
            }
        }
        dispatch_group_enter(serviceGroup)
        SNNet.get("https://www.google.com/tobefailed") { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let error = err {
                if let netError = err as? SNNetError where netError.res.statusCode == 404 {
                    MyLog("Google Invalid Search Failed as Expected", level: 1)
                } else {
                    MyLog("Google Invalid Search Failed With an Unexpected error: \(error)", level: 0)
                }
            } else {
                MyLog("Google Invalid Search Succeeded Unexpectedly", level: 0)
                errorCount += 1
            }
        }
        
        dispatch_group_notify(serviceGroup, dispatch_get_main_queue()) {
            if errorCount > 0 {
                print("Google: Complete with error count = ", errorCount)
            } else {
                print("Google: Complete")
            }
        }
    }
}

