//
//  ViewController.swift
//  SNNet
//
//  Created by satoshi on 7/25/16.
//  Copyright © 2016 Satoshi Nakajima. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        test()
    }

    func test() {
        SNNet.get("/webhp", params: [ "q":"hello world" ]) { (url, err) -> (Void) in
            print(url, err)
        }
    }
}

