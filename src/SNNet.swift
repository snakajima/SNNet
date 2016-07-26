//
//  SNNet.swift
//  canvas
//
//  Created by satoshi on 11/23/15.
//  Copyright © 2015 Satoshi Nakajima. All rights reserved.
//

import Foundation

private func MyLog(_ text:String, level:Int = 1) {
    let s_verbosLevel = 0
    if level <= s_verbosLevel {
        print(text)
    }
}

class SNNetError: NSObject, ErrorProtocol {
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

public typealias snnet_callback = (url:URL?, err:ErrorProtocol?)->(Void)

class SNNet: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    static let boundary = "0xKhTmLbOuNdArY---This_Is_ThE_BoUnDaRyy---pqo"

    static let sharedInstance = SNNet()
    static let session:Foundation.URLSession = {
        let config = URLSessionConfiguration.default
        return Foundation.URLSession(configuration: config, delegate: SNNet.sharedInstance, delegateQueue: OperationQueue.main)
    }()
    static var apiRoot = URL(string: "http://localhost")!
    
    static func deleteAllCookiesForURL(_ url:URL) {
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies(for: url) {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
    }

    static func get(_ path:String, params:[String:String]? = nil, callback:snnet_callback) -> URLSessionDownloadTask? {
        return SNNet.request("GET", path: path, params:params, callback:callback)
    }

    static func post(_ path:String, params:[String:String]? = nil, callback:snnet_callback) -> URLSessionDownloadTask? {
        return SNNet.request("POST", path: path, params:params, callback:callback)
    }

    static func put(_ path:String, params:[String:String]? = nil, callback:snnet_callback) -> URLSessionDownloadTask? {
        return SNNet.request("PUT", path: path, params:params, callback:callback)
    }

    static func delete(_ path:String, params:[String:String]? = nil, callback:snnet_callback) -> URLSessionDownloadTask? {
        return SNNet.request("DELETE", path: path, params:params, callback:callback)
    }

    static func post(_ path:String, json:[String:AnyObject], params:[String:String], callback:snnet_callback) -> URLSessionDownloadTask? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
            return post(path, fileData: data, params: params, callback: callback)
        } catch {
            callback(url: nil, err: error)
            return nil
        }
    }

    static func post(_ path:String, file:URL, params:[String:String], callback:snnet_callback) -> URLSessionDownloadTask? {
        guard let data = try? Data(contentsOf: file) else {
            // BUGBUG: callback with an error
            return nil
        }
        return post(path, fileData: data, params: params, callback: callback)
    }

    static func post(_ path:String, rawData:Data, callback:snnet_callback) -> URLSessionDownloadTask? {
        guard let url = urlFromPath(path) else {
            MyLog("SNNet Invalid URL:\(path)")
            // BUGBUG: callback with an error
            return nil
        }
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = rawData
        request.setValue("\(rawData.count)", forHTTPHeaderField: "Content-Length")

        return sendRequest(request as URLRequest, callback: callback)
    }
    
    static func post(_ path:String, fileData _fileData:Data?, params:[String:String], callback:snnet_callback) -> URLSessionDownloadTask? {
        guard let url = urlFromPath(path) else {
            MyLog("SNNet Invalid URL:\(path)")
            // BUGBUG: callback with an error
            return nil
        }
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"

        var body = ""
        for (name, value) in params {
            body += "\r\n--\(boundary)\r\n"
            body += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
            body += value
        }
        var data = NSData(data: body.data(using: String.Encoding.utf8)!) as Data
        
        if let fileData = _fileData {
            var extraBody = "\r\n--\(boundary)\r\n"
            extraBody += "Content-Disposition: form-data; name=\"file\"\r\n\r\n"
            
            data.append(extraBody.data(using: String.Encoding.utf8)!)
            data.append(fileData)
        }

        data.append("\r\n--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        request.httpBody = data
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        return sendRequest(request as URLRequest, callback: callback)
    }
    
    private static let regex = try! RegularExpression(pattern: "^https?:", options: RegularExpression.Options())
    
    private static func urlFromPath(_ path:String) -> URL? {
        if regex.matches(in: path, options: RegularExpression.MatchingOptions(), range: NSMakeRange(0, path.characters.count)).count > 0 {
            return URL(string: path)!
        }
        return try! apiRoot.appendingPathComponent(path)
    }
    
    private static func request(_ method:String, path:String, params:[String:String]? = nil, callback:snnet_callback) -> URLSessionDownloadTask? {
        guard let url = urlFromPath(path) else {
            MyLog("SNNet Invalid URL:\(path)")
            return nil
        }
        var query:String?
        if let p = params {
            var components = URLComponents(string: "http://foo")!
            components.queryItems = p.map({ (key:String, value:String?) -> URLQueryItem in
                return URLQueryItem(name: key, value: value)
            })
            if let urlQuery = components.url {
                query = urlQuery.query
            }
        }
        
        let request:NSMutableURLRequest
        if let q = query where method == "GET" {
            let urlGet = URL(string: url.absoluteString! + "?\(q)")!
            request = NSMutableURLRequest(url: urlGet)
            MyLog("SNNet \(method) url=\(urlGet.absoluteString)")
        } else {
            request = NSMutableURLRequest(url: url)
            MyLog("SNNet \(method) url=\(url.absoluteString) +\(query)")
        }

        request.httpMethod = method
        if let data = query?.data(using: String.Encoding.utf8) where method != "GET" {
            request.httpBody = data
            request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        return sendRequest(request as URLRequest, callback: callback)
    }

    private static func sendRequest(_ request:URLRequest, callback:snnet_callback) -> URLSessionDownloadTask {
        let task = session.downloadTask(with: request) { (url:URL?, res:URLResponse?, err:NSError?) -> Void in
            if let error = err {
                MyLog("SNNet ### error=\(error)")
                callback(url: url, err: err)
            } else {
                guard let hres = res as? HTTPURLResponse else {
                    MyLog("SNNet ### not HTTP Response=\(res)")
                    // NOTE: Probably never happens
                    return
                }
                if (200..<300).contains(hres.statusCode) {
                    callback(url: url, err: nil)
                } else {
                    callback(url: url, err: SNNetError(res: hres))
                }
            }
        }
        task.resume()
        return task
    }
    
    static let didSentBytes = "didSentBytes"
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SNNet.didSentBytes), object: task)
    }
}
