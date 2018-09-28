//
//  SNNet.swift
//  canvas
//
//  Created by satoshi on 11/23/15.
//  Copyright © 2015 Satoshi Nakajima. All rights reserved.
//

import UIKit

class SNNetError: NSObject, Error {
    let res:HTTPURLResponse
    init(res:HTTPURLResponse) {
        self.res = res
    }

    var localizedDescription:String {
        // LAZY
        return self.description
    }
    
    override var description:String {
        let message:String
        switch(res.statusCode) {
        case 400:
            message = "Bad Request"
        case 401:
            message = "Unauthorized"
        case 402:
            message = "Payment Required"
        case 403:
            message = "Forbidden"
        case 404:
            message = "Not Found"
        case 405:
            message = "Method Not Allowed"
        case 406:
            message = "Proxy Authentication Required"
        case 407:
            message = "Request Timeout"
        case 408:
            message = "Request Timeout"
        case 409:
            message = "Conflict"
        case 410:
            message = "Gone"
        case 411:
            message = "Length Required"
        case 500:
            message = "Internal Server Error"
        case 501:
            message = "Not Implemented"
        case 502:
            message = "Bad Gateway"
        case 503:
            message = "Service Unavailable"
        case 504:
            message = "Gateway Timeout"
        default:
            message = "HTTP Error"
        }
        return "\(message) (\(res.statusCode))"
    }
}

extension UIViewController {
    func showError(title:String, message:String, error:Error?, retry:(()->(Void))? = nil, ok:(()->(Void))? = nil) {
        let extra:String
        if let snerr = error as? SNNetError {
            extra = "\n\(snerr)"
        } else if let err = error {
            extra = "\n\(err.localizedDescription)"
        } else {
            extra = ""
        }

        let alert = UIAlertController(title: title, message: message + extra, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel)  { (_:UIAlertAction) -> Void in
                if let callback = ok {
                    callback()
                }
            }
        )
        if let callback = retry {
            let action = UIAlertAction(title: "Retry".localized, style: .default) { (_:UIAlertAction) -> Void in
                callback()
            }
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
}

class SNNet: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    static let boundary = "0xKhTmLbOuNdArY---This_Is_ThE_BoUnDaRyy---pqo"

    static let sharedInstance = SNNet()
    static let session:URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: SNNet.sharedInstance, delegateQueue: OperationQueue.main)
    }()
    static var apiRoot = URL(string: "https://www.google.com")!
    
    static func deleteAllCookies(for url:URL) {
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies(for: url) {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
    }

    @discardableResult
    static func get(_ path:String, params:[String:String]? = nil, callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        return SNNet.request("GET", path: path, params:params, callback:callback)
    }

    @discardableResult
    static func post(_ path:String, params:[String:String]? = nil, callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        return SNNet.request("POST", path: path, params:params, callback:callback)
    }

    @discardableResult
    static func put(_ path:String, params:[String:String]? = nil, callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        return SNNet.request("PUT", path: path, params:params, callback:callback)
    }

    @discardableResult
    static func delete(_ path:String, params:[String:String]? = nil, callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        return SNNet.request("DELETE", path: path, params:params, callback:callback)
    }

    @discardableResult
    static func post(_ path:String, json:[String:Any], params:[String:String], callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            return post(path, fileData: data, params: params, callback: callback)
        } catch {
            callback(nil, error)
            return nil
        }
    }

    @discardableResult
    static func post(_ path:String, file:URL, params:[String:String], callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        guard let data = try? Data(contentsOf: file) else {
            // BUGBUG: callback with an error
            return nil
        }
        return post(path, fileData: data, params: params, callback: callback)
    }

    @discardableResult
    static func post(_ path:String, fileData:Data, params:[String:String], callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        guard let url = url(from: path) else {
            print("SNNet Invalid URL:\(path)")
            // BUGBUG: callback with an error
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        var body = ""
        for (name, value) in params {
            body += "\r\n--\(boundary)\r\n"
            body += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
            body += value
        }
        body += "\r\n--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"file\"\r\n\r\n"
        
        //print("SNNet FILE body:\(body)")

        var data = body.data(using: String.Encoding.utf8)!

        data.append(fileData)
        data.append("\r\n--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        request.httpBody = data
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        return sendRequest(request, callback: callback)
    }
    
    private static let regex = try! NSRegularExpression(pattern: "^https?:", options: NSRegularExpression.Options())
    
    private static func url(from path:String) -> URL? {
        if regex.matches(in: path, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, path.count)).count > 0 {
            return URL(string: path)!
        }
        return apiRoot.appendingPathComponent(path)
    }
    
    private static func encode(_ string: String) -> String {
        // URL encoding: RFC 3986 http://www.ietf.org/rfc/rfc3986.txt
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "-._~")
        
        // The following force-unwrap fails if the string contains invalid UTF-16 surrogate pairs,
        // but the case can be ignored unless a string is constructed from UTF-16 byte data.
        // http://stackoverflow.com/a/33558934/4522678
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!
    }
    
    private static func request(_ method:String, path:String, params:[String:String]? = nil, callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask? {
        guard let url = url(from: path) else {
            print("SNNet Invalid URL:\(path)")
            return nil
        }
        var query:String?
        if let p = params {
            query = p.map { (key, value) in "\(key)=\(encode(value))" }.joined(separator: "&")
        }
        
        var request:URLRequest
        if let q = query, method == "GET" {
            let urlGet = URL(string: url.absoluteString + "?\(q)")!
            request = URLRequest(url: urlGet)
            print("SNNet \(method) url=\(urlGet)")
        } else {
            request = URLRequest(url: url)
            print("SNNet \(method) url=\(url) +\(query ?? "")")
        }

        request.httpMethod = method
        if let data = query?.data(using: String.Encoding.utf8), method != "GET" {
            request.httpBody = data
            request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        return sendRequest(request, callback: callback)
    }

    private static func sendRequest(_ request:URLRequest, callback:@escaping (URL?, Error?)->(Void)) -> URLSessionDownloadTask {
        let task = session.downloadTask(with: request) { (url:URL?, res:URLResponse?, err:Error?) -> Void in
            if let error = err {
                print("SNNet ### error=\(error)")
                callback(url, err)
            } else {
                guard let hres = res as? HTTPURLResponse else {
                    print("SNNet ### not HTTP Response=\(String(describing: res))")
                    // NOTE: Probably never happens
                    return
                }
                if (200..<300).contains(hres.statusCode) {
                    callback(url, nil)
                } else {
                    let netError = SNNetError(res: hres)
                    print("SNNet ### http error \(netError)")
                    callback(url, netError)
                }
            }
        }
        task.resume()
        return task
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        NotificationCenter.default.post(name: .SNNetDidSentBytes, object: task)
    }
}

extension Notification.Name {
    static let SNNetDidSentBytes = Notification.Name("SNNetDidSentBytes")
}
