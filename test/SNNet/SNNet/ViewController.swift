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
        
        SNNet.apiRoot = NSURL(string:"http://localhost:3000")!

        dispatch_group_enter(serviceGroup)
        SNNet.get("/test1") { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("Local test1 Faied", level: 0)
                errorCount += 1
            } else {
                MyLog("Local test1 Succeeded", level: 1)
            }
        }

        dispatch_group_enter(serviceGroup)
        SNNet.get("/test2") { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("Local test2 Failed as expected", level: 1)
            } else {
                MyLog("Local test2 Succeeded unexpectedly", level: 0)
                errorCount += 1
            }
        }
        
        //let image = UIImage(named:"swipe.png")!
        //let data = UIImagePNGRepresentation(image)!
        let message = "Hello World. This is a message body."
        let data = message.dataUsingEncoding(NSUTF8StringEncoding)!

        dispatch_group_enter(serviceGroup)
        SNNet.post("/post1", rawData: data) { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("Local post1 Faied", level: 0)
                errorCount += 1
            } else {
                if let urlLocal = url {
                    let messageReceived = try! NSString(contentsOfURL: urlLocal, encoding: NSUTF8StringEncoding)
                    //print("message=", messageReceived)
                    if message == messageReceived {
                        MyLog("Local post1 Succeeded", level: 1)
                    } else {
                        MyLog("Local post1 Faied: wrong message", level: 0)
                        errorCount += 1
                    }
                } else {
                    MyLog("Local post1 Faied: no url", level: 0)
                    errorCount += 1
                }
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
        SNNet.get("http://httpbin.org/get", params: [ "message":"Hello World" ]) { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("httpbin get test Faied", level: 0)
                errorCount += 1
            } else {
                if let urlLocal = url,
                   let data = NSData(contentsOfURL:urlLocal) {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        //print("json", json)
                        if let args = json["args"] as? [String:AnyObject],
                           let message = args["message"] as? String where message == "Hello World" {
                                MyLog("httpbin get test Succeeded", level: 1)
                           } else {
                                MyLog("httpbin get test failed, no message", level: 0)
                                errorCount += 1
                           }
                    } catch let error as NSError {
                        MyLog("httpbin get test failed, json error, \(error)", level: 0)
                        errorCount += 1
                    }
                }
            }
        }

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
        
        dispatch_group_enter(serviceGroup)
        SNNet.post("http://httpbin.org/post", fileData: nil, params:["message":"Hello World"]) { (url, err) -> (Void) in
            dispatch_group_leave(serviceGroup)
            if let _ = err {
                MyLog("httpbin post test Faied", level: 0)
                errorCount += 1
            } else {
                if let urlLocal = url,
                   let data = NSData(contentsOfURL:urlLocal) {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        //print("json", json)
                        if let form = json["form"] as? [String:AnyObject],
                           let message = form["message"] as? String where message == "Hello World" {
                                MyLog("httpbin post test Succeeded", level: 1)
                           } else {
                                MyLog("httpbin post test failed, no message", level: 0)
                                errorCount += 1
                           }
                    } catch let error as NSError {
                        MyLog("httpbin post test failed, json error, \(error)", level: 0)
                        errorCount += 1
                    }
                }
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

