//
//  File.swift
//  
//
//  Created by Michal Bencur on 13.08.23.
//

import Foundation

public class JSConsoleLogger: JSLogger {
    public init() {
    }
    
    public func log(_ string: String) {
        print("JS:", string)
    }
}
