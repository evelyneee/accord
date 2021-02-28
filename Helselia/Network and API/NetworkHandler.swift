//
//  NetworkHandler.swift
//  Helselia
//
//  Created by evelyn on 2021-02-27.
//


import Foundation

class GetMessages {
    func getMessageArray(url: String, Bearer: String, Cookie: String) -> [[String:Any]] {
        var completion: Bool = false
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: (URL(string: url) ?? URL(string: "#"))!)
        var retData: Data = Data()
        request.httpMethod = "GET"
        request.addValue(Bearer, forHTTPHeaderField: "Authorization")
        request.addValue(Cookie, forHTTPHeaderField: "Cookie")
        var messagesArray: [[String:Any]] = []
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                retData = Data(data!)
                do {
                    messagesArray = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] ?? [[String:Any]]()
                } catch {
                    print("error at serializing: \(error.localizedDescription)")
                }
                print("URL Session Task Succeeded: HTTP \(statusCode)")
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        while retData == Data() {
            task.resume()
            session.finishTasksAndInvalidate()
            sleep(1)
        }
        return messagesArray
    }
    
    func restructureToMessage(array: [[String:Any]]) -> [Message] {
        var retMessages: [Message] = []
        for (i, message) in array.enumerated() {
            for i in message.keys {
                print("---- begin dict preview -------")
                print(message[i] as Any)
                print(i)
                print(type(of: message[i]))
                print("---- end dict preview -------")
                for i in message[i] as? [String:Any] ?? [:] {
                    print("uhhhhhhhhhhhhhh")
                    print(i)
                    print("uhhhhhhhhhhhhhh")
                }
            }
        }
        return retMessages
    }
}
