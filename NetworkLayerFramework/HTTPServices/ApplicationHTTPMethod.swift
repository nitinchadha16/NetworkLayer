//
//  ApplicationHTTPMethod.swift
//  Goibibo
//
//  Created by Abhijeet Rai on 04/07/18.
//  Copyright © 2018 ibibo Web Pvt Ltd. All rights reserved.
//

import Foundation

public typealias HTTPParameters = [String: Any]

/// Enum for various HTTP methods
public enum ApplicationHTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
