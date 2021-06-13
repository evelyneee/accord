//
//  NetworkHandler.swift
//  Helselia
//
//  Created by evelyn on 2021-02-27.
//


import Foundation

let debug = true

final class NetworkHandling {
    static var shared = NetworkHandling()
    func request(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ array: [[String:Any]]?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)
        var retData: Data?
        
        // setup of the request
        switch type {
        case .GET:
            request.httpMethod = "GET"
        case .POST:
            request.httpMethod = "POST"
        case .PATCH:
            request.httpMethod = "PATCH"
        case .DELETE:
            request.httpMethod = "DELETE"
        case .PUT:
            request.httpMethod = "PUT"
        }
        
        // helselia specific stuff starts here
        
        if token != nil {
            request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        }
        if json == false && type == .POST {
            let bodyString = (bodyObject as? [String:String] ?? [:]).queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }
        var returnArray: [[String:Any]] = []
        
        // ends here
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                if let data = data {
                    do {
                        returnArray = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                        return completion(true, returnArray)
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                        return
                    }
                } else {
                    returnArray = [["Code":statusCode]]
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields)
                    print(request.url)
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        return completion(false, nil)
    }
    func requestData(url: String, token: String?, json: Bool, type: requests.requestTypes, bodyObject: [String:Any], _ completion: @escaping ((_ success: Bool, _ data: Data?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)
        var retData: Data?
        
        // setup of the request
        switch type {
        case .GET:
            request.httpMethod = "GET"
        case .POST:
            request.httpMethod = "POST"
        case .PATCH:
            request.httpMethod = "PATCH"
        case .DELETE:
            request.httpMethod = "DELETE"
        case .PUT:
            request.httpMethod = "PUT"
        }
        
        // helselia specific stuff starts here
        
        if token != nil {
            request.addValue(token ?? "", forHTTPHeaderField: "Authorization")
        }
        if json == false && type == .POST {
            let bodyString = (bodyObject as? [String:String] ?? [:]).queryParameters
            request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
            request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if type == .POST && json == true {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        }
        // ends here
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                if let data = data {
                    do {
                        return completion(true, data)
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                        return
                    }
                } else {
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields)
                    print(request.url)
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        return completion(false, nil)
    }
    func login(username: String, password: String, _ completion: @escaping ((_ success: Bool, _ rettoken: String?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: "https://constanze.live/api/v1/auth/login") ?? URL(string: "#")!))
        var retData: Data?
        
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Form URL-Encoded Body
        let bodyObject: [String : Any] = [
            "email": username,
            "password": password
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        var token: String = ""
        
        // ends here
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                print("success \(Date())")
                let statusCode = (response as! HTTPURLResponse).statusCode
                if data != Data() {
                    do {
                        let returnArray = try JSONSerialization.jsonObject(with: data ?? Data(), options: .mutableContainers) as? [String:Any] ?? [String:Any]()
                        if let checktoken = returnArray["token"] as? String {
                            return completion(true, checktoken)
                        }
                    } catch {
                        print("error at serializing: \(error.localizedDescription)")
                    }
                } else {
                }
                if debug {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    print(request.allHTTPHeaderFields)
                    print(request.httpBody)
                }
            }
            else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        return completion(false, nil)
    }
}
