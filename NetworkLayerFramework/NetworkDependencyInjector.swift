//
//  NetworkDependencyInjector.swift
//  NetworkLayerFramework
//
//  Created by Nitin Chadha on 28/11/19.
//  Copyright © 2019 Nitin Chadha. All rights reserved.
//

import UIKit

public class NetworkDependencyInjector {

    internal static var sessionAdapter: RequestAdapter?
    internal static var sessionRetrier: RequestRetrier?
    
    public static func initDepedencies(sessionAdapter: RequestAdapter, sessionRetrier: RequestRetrier) {
        self.sessionAdapter = sessionAdapter
        self.sessionRetrier = sessionRetrier
    }
}
