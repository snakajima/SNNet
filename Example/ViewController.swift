//
//  ViewController.swift
//
//  Created by ToKoRo on 2016-07-26.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var textView: UITextView?

    let scheme = "https"
    let host = "api.github.com"
    let path = "/search/repositories"

    var searchKeyword: String? {
        return textField?.text
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = NSURL(string: "\(scheme)://\(host)") else {
            return
        }
        SNNet.apiRoot = url
    }

    @IBAction func getButtonDidTap(sender: AnyObject) {
        execute() { [weak self] text, error in
            if let error = error {
                self?.gotText(String(error))
            } else if let text = text {
                self?.gotText(text)
            }
        }
    }

    func execute(callback: (String?, ErrorType?) -> Void) {
        guard let searchKeyword = searchKeyword else {
            return
        }

        let params: [String: String] = [
            "q": searchKeyword,
        ]

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        SNNet.get(path, params: params) { url, error in
            defer {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }

            if let error = error {
                callback(nil, error)
                return
            }

            guard
                let url = url,
                data = NSData(contentsOfURL: url),
                text = String(data: data, encoding: NSUTF8StringEncoding)
            else {
                callback(nil, Error.invalidData)
                return
            }

            callback(text, nil)
        }
    }

    func gotText(text: String) {
        textView?.text = text
    }

    enum Error: ErrorType {
        case invalidData
    }
}
