//
//  Session.swift
//  Goibibo
//
//  Created by Abhijeet Rai on 04/07/18.
//  Copyright © 2018 ibibo Web Pvt Ltd. All rights reserved.
//

import Foundation

public extension TimeInterval {
    static let `default`: TimeInterval = 30
    static let download: TimeInterval = 180
    static let upload: TimeInterval = 300
}

public class Session {
    
    public static let service = Session()
    
    var sessionManagers = [AnyHashable: SessionManager]()

    
    /// The request adapter called each time a new request is created.
    var sessionAdapter: RequestAdapter?
    
    /// The request retrier called each time a request encounters an error to determine whether to retry the request.
    var sessionRetrier: RequestRetrier?
    
    /// Responsible for managing the mapping of `ServerTrustPolicy` objects to a given host.
    var serverTrustPolicyManager: ServerTrustPolicyManager?
    
    private init() {
        sessionAdapter = NetworkDependencyInjector.sessionAdapter
        sessionRetrier = NetworkDependencyInjector.sessionRetrier
    }
    
    private func getSessionManager(_ timeoutInterval: TimeInterval = .default, path: URLConvertible) -> SessionManager {
        
        if timeoutInterval == .default, let domain = try? path.asURL().host {
            var sessionManager = self.sessionManagers[domain]
            
            if sessionManager != nil {
                return sessionManager!
            } else {
                sessionManager = createSessionManager(timeoutInterval)
                sessionManagers[domain] = sessionManager
                return sessionManager!
            }
        } else {
            var sessionManager = self.sessionManagers[timeoutInterval]
            
            if sessionManager != nil {
                return sessionManager!
            } else {
                sessionManager = createSessionManager(timeoutInterval)
                sessionManagers[timeoutInterval] = sessionManager
                return sessionManager!
            }
        }
    }
    
    private func createSessionManager(_ timeoutInterval: TimeInterval) -> SessionManager {
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GoNetworkSessionCreated"), object: configuration)
        let sessionManager = SessionManager(configuration: configuration, delegate: SessionDelegate(), serverTrustPolicyManager: serverTrustPolicyManager)
        
        if sessionAdapter != nil {
            sessionManager.adapter = sessionAdapter
        }
        
        if sessionRetrier != nil {
            sessionManager.retrier = sessionRetrier
        }
        return sessionManager
    }
    
    // MARK: - methods
    
    /// Cancel all ongoing requests
    ///
    /// - Returns: nothing
    public func cancelAllRequests() {
        for sessionManager in sessionManagers {
            sessionManager.value.session.getAllTasks { tasks in
                tasks.forEach { $0.cancel() }
            }
        }
    }
    
    /// Use this request to retrieve a single object.
    ///
    /// - Parameters:
    ///   - path: The href/URL string where content is retrieved
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    @discardableResult
    public func get(_ path:String, success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) -> Void) -> DataRequest {
        
        return self.get(path, header: nil, parameters: nil, timeoutInterval: .default, success: success, failure: failure)
    }
    
    /// Use this request to retrieve a single object.
    ///
    /// - Parameters:
    ///   - path: The href/URL string where content is retrieved
    ///   - header: The HTTP headers
    ///   - parameters: HTTP parameters
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    ///   - timeoutInterval: The timeout interval for the request
    @discardableResult
    public func get(_ path:String, header:HTTPHeaders? = nil, parameters: Parameters? = nil, timeoutInterval : TimeInterval = .default, success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) -> Void) -> DataRequest {
        
        return self.request(path, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: header, timeoutInterval: timeoutInterval).validate().responseJSON { [unowned self] response in
            
            self.handleResponse(response, success: success, failure: failure)
        }
    }
    
    /// Use this request to retrieve a string result.
    ///
    /// - Parameters:
    ///   - path: The href/URL string where content is retrieved
    ///   - header: HTTP headers
    ///   - parameters: HTTP parameters
    ///   - completionHandler: The closure called with response when request is completed
    ///   - timeoutInterval: The timeout interval for the request
    @discardableResult
    public func get(stringFromURL path:String, header:HTTPHeaders? = nil, parameters: Parameters? = nil, completionHandler:@escaping (String?) -> Void, timeoutInterval : TimeInterval = .default) -> DataRequest {
        
        return self.request(path, method: .get, parameters: parameters, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().responseString { (response:DataResponse<String>) in
                
                if response.data == nil {
                    completionHandler(nil)
                }
                
                if response.result.isSuccess {
                    if let dataToString = String(data: response.data!, encoding: String.Encoding.utf8) {
                        completionHandler(dataToString)
                    } else {
                        completionHandler(nil)
                    }
                } else {
                    completionHandler(nil)
                }
        }
    }
    
    /// Use this request to retrieve a list of object.
    ///
    /// - Parameters:
    ///   - path: The href/URL string where content is retrieved
    ///   - header: HTTP headers
    ///   - parameters: HTTP parameters
    ///   - keypath: The starting point of response
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    ///   - timeoutInterval: The timeout interval for the request
    @discardableResult
    public func getAll(_ path:String, header: HTTPHeaders? = nil, parameters: Parameters? = nil, keypath:String? = nil, success:@escaping ([JSON]) -> Void, failure:@escaping (JSON?, Error?) -> Void, timeoutInterval : TimeInterval = .default) -> DataRequest {
        
        return self.request(path, parameters: parameters, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().responseJSON { [unowned self] response in
            self.handleResponse(response, keypath: keypath, success: success, failure: failure)
        }
    }
    
    /// Use this request to add an object with header
    ///
    /// - Parameters:
    ///   - path: The href/URL string where @data to be added
    ///   - data: The dictionary to be added
    ///   - header: The HTTP headers
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    ///   - timeoutInterval: The timeout interval for the request
    public func post(_ path:String, data:Parameters, header: HTTPHeaders? ,success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) -> Void, timeoutInterval : TimeInterval = .default) {
        
        self.request(path, method: .post, parameters:data, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().responseJSON { [unowned self] response in
            
            self.handleResponse(response, success: success, failure: failure)
        }
    }
    
    /// Use this request to add an object with header
    ///
    /// - Parameters:
    ///   - path: The href/URL string where @data to be added
    ///   - data: The dictionary to be added
    ///   - header: The HTTP headers
    ///   - encoding: URL Encoding
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    ///   - timeoutInterval: The timeout interval for the request
    public func post(_ path:String, data:Parameters, header: HTTPHeaders?, encoding: URLEncoding ,success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) -> Void, timeoutInterval : TimeInterval = .default) {
        
        self.request(path, method: .post, parameters:data, encoding: encoding, headers: header, timeoutInterval: timeoutInterval).validate().responseJSON { [unowned self] response in
            
            self.handleResponse(response, success: success, failure: failure)
        }
    }
    
    
    
    /// Use this request to get data in chunks from streamed API
    ///
    /// - Parameters:
    ///   - path: The href/URL string where @data to be added
    ///   - data: The dictionary to be added
    ///   - header: The HTTP headers
    ///   - dataStream: The closure called with response when chunk arrived
    ///   - timeoutInterval: The timeout interval for the request
    public func postStream(_ path:String, data: Parameters, header: HTTPHeaders?, dataStream: @escaping (Data) -> Void, failure:@escaping (JSON?, Error?) -> Void  ,timeoutInterval : TimeInterval = .download ) {
        
        self.request(path, method: .post, parameters:data, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().stream { (data) in
            dataStream(data)
            }.response { (response) in
            self.handleStreamingErrorResponse(response, failure: failure)
        }
    }
    
    /// Use this request to get data in chunks from streamed API
    ///
    /// - Parameters:
    ///   - path: The href/URL string where @data to be added
    ///   - data: The dictionary to be added
    ///   - header: The HTTP headers
    ///   - dataStream: The closure called with response when chunk arrived
    ///   - timeoutInterval: The timeout interval for the request
    public func getStream(_ path:String, header: HTTPHeaders?, dataStream: @escaping (Data) -> Void, failure:@escaping (JSON?, Error?) -> Void  ,timeoutInterval : TimeInterval = .download ) {
        
        self.request(path, method: .get, parameters:nil, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().stream { (data) in
            dataStream(data)
            }.response { (response) in
                self.handleStreamingErrorResponse(response, failure: failure)
        }
    }
    
    /// Use this request to update an object
    ///
    /// - Parameters:
    ///   - path: The href/URL string where @data to be updated
    ///   - data: The object dictionary to be updated
    ///   - header: The HTTP headers
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    ///   - timeoutInterval: The timeout interval for the request
    public func put(_ path:String, _ data:Parameters, header:HTTPHeaders?, success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) -> Void, timeoutInterval : TimeInterval = .default) {
        
        self.request(path, method: .put, parameters: data, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().responseJSON { [unowned self] response in
            self.handleResponse(response, success: success, failure: failure)
        }
    }
    
    /// Use this request to delete an object
    ///
    /// - Parameters:
    ///   - path: The href/URL string of object to be delete
    ///   - header: The HTTP headers
    ///   - success: The closure called when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    ///   - timeoutInterval: The timeout interval for the request
    public func delete (_ path:String, header:HTTPHeaders?, success:@escaping () -> Void, failure:@escaping (JSON?, Error?) -> Void, timeoutInterval : TimeInterval = .default) {
        
        self.request(path, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: header, timeoutInterval: timeoutInterval).validate().responseString { [unowned self] response in
            self.handleResponse(response, success: success, failure: failure)
        }
    }
    
    /// Use this request to upload a file
    ///
    /// - Parameters:
    ///   - fileURL: URL of file to be uploaded
    ///   - path: The path where file to be uploaded
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error
    public func uploadFile(_ fileURL:String, _ path:String, success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) ->Void) {
        
        let url = URL(string:fileURL)
        
        self.getSessionManager(.upload, path: path).upload(url!, to: path).responseJSON { response in
            try? success(JSON(data: response.data!))
        }
    }
    
    /// Use this request to upload multiple file
    ///
    /// - Parameters:
    ///   - files: The Files data to be added
    ///   - fileIdentifiers: File Identifiers to be added to payload
    ///   - path: The path where file to be uploaded
    ///   - header: The HTTP headers
    ///   - success: The closure called with response when request is completed successfully
    ///   - failure: The closure called with error object when request is completed with error

   // public func uploadFiles(_ files: [Data], fileNames: [String], name: [String]? = nil, path:String, mimeType: String, header:[String: String]? = nil, success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) ->Void) {

    
    public func uploadFiles(_ files: [Data], fileNames: [String], name: [String]? = nil , path:String, mimeType: String, header:[String: String]? = nil, success:@escaping (JSON) -> Void, failure:@escaping (JSON?, Error?) ->Void) {
        
        self.getSessionManager(.upload, path: path).upload(multipartFormData: { (multipartFormData: MultipartFormData) in
            var index = 0
            for file in files {
                var page = "page\(index+1)"
                if let pg = name?[index] {
                    page = pg
                }
                multipartFormData.append(file, withName: page, fileName: fileNames[index], mimeType: mimeType)
                index += 1
            }
        }, usingThreshold: UInt64(), to: path, method: .post, headers: header, encodingCompletion: { encodingResult in
            
            switch encodingResult {
            case .success(let upload, _, _):
                upload.validate().responseJSON(completionHandler: { [unowned self] response in
                    self.handleResponse(response, success: success, failure: failure)
                })
            case .failure(let error):
                failure(nil, error)
            }
        })
    }
    
    
    /// Use this request to download a file
    ///
    /// - Parameters:
    ///   - path: Path from where file to be download
    ///   - destination: The URL where file will be saved locally on device
    ///   - header: The HTTP headers
    ///   - completionHandler: The closure called with response and error when request is completed
    public func downloadFile(_ path: String, to destination:URL, header:[String:String]?, completionHandler: @escaping (URLResponse?, Error?) -> Swift.Void) {
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (destination, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let url = URL(string: path)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = header
        
        self.getSessionManager(.download, path: path).download(request, to: destination).validate().response { response in
            
            completionHandler(response.response, response.error)
        }
    }
    
    // MARK: - Private methods
    
    private func handleResponse(_ response: DataResponse<Any>, success: (JSON) -> Void, failure: (JSON?, Error?) -> Void) {
        
        if response.result.isSuccess {
            do {
                try success(JSON(data: response.data!))
            } catch {
                let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                failure(nil, errorInfo)
            }
        } else {
            
            if response.response != nil {
                if response.data != nil && response.data!.count != 0 && response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    do {
                        try failure(JSON(data: response.data!), errorInfo)
                    } catch {
                        failure(nil, errorInfo)
                    }
                } else if response.data != nil && response.data!.count != 0 {
                    do {
                        try failure(JSON(data: response.data!), nil)
                    } catch {
                        let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                        failure(nil, errorInfo)
                    }
                } else if response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    failure(nil, errorInfo)
                } else {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                    failure(nil, errorInfo)
                }
                
            } else {
//                print(String(describing:response.result.error?.localizedDescription))
                failure(nil, response.result.error)
            }
        }
    }
    
    private func handleResponse(_ response: DataResponse<Any>, keypath:String? = nil, success: ([JSON]) -> Void, failure: (JSON?, Error?) -> Void) {
        
        if response.result.isSuccess {
            if keypath != nil {
                do {
                    try success(JSON(data: response.data!)[keypath!].arrayValue)
                } catch {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    failure(nil, errorInfo)
                }
            } else {
                do {
                    try success(JSON(data: response.data!).arrayValue)
                } catch {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    failure(nil, errorInfo)
                }
            }
        } else {
            
            if response.response != nil {
                if response.data != nil && response.data!.count != 0 && response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    do {
                        try failure(JSON(data: response.data!), errorInfo)
                    } catch {
                        failure(nil, errorInfo)
                    }
                } else if response.data != nil && response.data!.count != 0 {
                    do {
                        try failure(JSON(data: response.data!), nil)
                    } catch {
                        let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                        failure(nil, errorInfo)
                    }
                } else if response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    failure(nil, errorInfo)
                } else {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                    failure(nil, errorInfo)
                }
                
            } else {
//                print(String(describing:response.result.error?.localizedDescription))
                failure(nil, response.result.error)
            }
        }
    }
    
    private func handleResponse(_ response: DataResponse<String>, success: () -> Void, failure: (JSON?, Error?) -> Void) {
        
        if response.result.isSuccess {
            success()
        } else {
            
            if response.response != nil {
                if response.data != nil && response.data!.count != 0 && response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    do {
                        try failure(JSON(data: response.data!), errorInfo)
                    } catch {
                        failure(nil, errorInfo)
                    }
                } else if response.data != nil && response.data!.count != 0 {
                    do {
                        try failure(JSON(data: response.data!), nil)
                    } catch {
                        let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                        failure(nil, errorInfo)
                    }
                } else if response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    failure(nil, errorInfo)
                } else {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                    failure(nil, errorInfo)
                }
            } else {
//                print(String(describing:response.result.error?.localizedDescription))
                failure(nil, response.result.error)
            }
        }
    }
    
    private func handleResponse(_ response: DataResponse<Any>, success: (JSON, JSON) -> Void, failure: (JSON?, Error?) -> Void) {
        
        if response.result.isSuccess {
            
            do {
                try success(JSON(data: response.data!), JSON(response.response!.allHeaderFields))
            } catch {
                let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                failure(nil, errorInfo)
            }
        } else {
            
            if response.response != nil {
                
                if response.data != nil && response.data!.count != 0 && response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    do {
                        try failure(JSON(data: response.data!), errorInfo)
                    } catch {
                        failure(nil, errorInfo)
                    }
                } else if response.data != nil && response.data!.count != 0 {
                    do {
                        try failure(JSON(data: response.data!), nil)
                    } catch {
                        let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                        failure(nil, errorInfo)
                    }
                } else if response.error != nil {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                    failure(nil, errorInfo)
                } else {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                    failure(nil, errorInfo)
                }
                
            } else {
//                print(String(describing:response.result.error?.localizedDescription))
                failure(nil, response.result.error)
            }
        }
    }
    
    private func handleStreamingErrorResponse(_ response: DefaultDataResponse, failure: (JSON?, Error?) -> Void){
        if response.response != nil {
            if response.data != nil && response.data!.count != 0 && response.error != nil {
                let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                do {
                    try failure(JSON(data: response.data!), errorInfo)
                } catch {
                    failure(nil, errorInfo)
                }
            } else if response.data != nil && response.data!.count != 0 {
                do {
                    try failure(JSON(data: response.data!), nil)
                } catch {
                    let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                    failure(nil, errorInfo)
                }
            } else if response.error != nil {
                let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: response.error?.localizedDescription ?? ""])
                failure(nil, errorInfo)
            } else {
                let errorInfo = NSError(domain: "", code: response.response!.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                failure(nil, errorInfo)
            }
            
        } else {
            //print(String(describing:response.result.error?.localizedDescription))
            failure(nil, response.error)
        }
    }
    
    /// Creates a `DataRequest` to retrieve the contents of the specified `url`, `method`, `parameters`, `encoding`
    /// and `headers`.
    ///
    /// - parameter url:        The URL.
    /// - parameter method:     The HTTP method. `.get` by default.
    /// - parameter parameters: The parameters. `nil` by default.
    /// - parameter encoding:   The parameter encoding. `URLEncoding.default` by default.
    /// - parameter headers:    The HTTP headers. `nil` by default.
    /// - timeoutInterval: The timeout interval for the request
    ///
    /// - returns: The created `DataRequest`.
    @discardableResult
    private func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        timeoutInterval: TimeInterval = .default)
        -> DataRequest
    {
        return self.getSessionManager(timeoutInterval, path: url).request(url, method: method, parameters:parameters, encoding: encoding, headers: headers)
    }
}

