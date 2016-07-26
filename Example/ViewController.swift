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

        guard let url = URL(string: "\(scheme)://\(host)") else {
            return
        }
        SNNet.apiRoot = url
    }

    @IBAction func getButtonDidTap(_ sender: AnyObject) {
        execute() { [weak self] text, error in
            if let error = error {
                self?.gotText(String(error))
            } else if let text = text {
                self?.gotText(text)
            }
        }
    }

    func execute(_ callback: (String?, ErrorProtocol?) -> Void) {
        guard let searchKeyword = searchKeyword else {
            return
        }

        let params: [String: String] = [
            "q": searchKeyword,
        ]

        UIApplication.shared().isNetworkActivityIndicatorVisible = true

        SNNet.get(path, params: params) { url, error in
            defer {
                UIApplication.shared().isNetworkActivityIndicatorVisible = false
            }

            if let error = error {
                callback(nil, error)
                return
            }

            guard
                let url = url,
                data = try? Data(contentsOf: url),
                text = String(data: data, encoding: String.Encoding.utf8)
            else {
                callback(nil, Error.invalidData)
                return
            }

            callback(text, nil)
        }
    }

    func gotText(_ text: String) {
        textView?.text = text
    }

    enum Error: ErrorProtocol {
        case invalidData
    }
}
