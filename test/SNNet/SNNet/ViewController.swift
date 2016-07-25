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
        testHTTPBIN()
    }
    
    func testLocal() {
        var errorCount = 0
        let serviceGroup = dispatch_group_create()
        
        dispatch_group_enter(serviceGroup)
        SNNet.apiRoot = NSURL(string:"http://localhost:3000")!
        SNNet.get("/test1") { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("Local test1 Faied", level: 0)
                errorCount += 1
            } else {
                MyLog("Local test1 Succeeded", level: 1)
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

    func testHTTPBIN() {
        var errorCount = 0
        let serviceGroup = dispatch_group_create()
        
        dispatch_group_enter(serviceGroup)
        SNNet.get("http://httpbin.org/status/418") { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let error = err {
                if let netError = err as? SNNetError where netError.res.statusCode == 418 {
                    MyLog("httpbin status code test succeeded", level: 1)
                } else {
                    MyLog("httpbin status code test Faied \(error)", level: 0)
                    errorCount += 1
                }
            } else {
                MyLog("httpbin status code test succeeded unexpectedly", level: 0)
                errorCount += 1
            }
        }
        
        dispatch_group_notify(serviceGroup, dispatch_get_main_queue()) {
            if errorCount > 0 {
                print("httpbin: Complete with error count = ", errorCount)
            } else {
                print("httpbin: Complete")
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
                    errorCount += 1
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

