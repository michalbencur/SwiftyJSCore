//
//  JSIntepreter+Setup.swift
//  
//
//  Created by Michal Bencur on 15.08.23.
//

import Foundation
import JavaScriptCore

extension JSInterpreter {
    func setupGlobal() throws {
        _ = context.evaluateScript("""
                var global = this;
                var window = this;
            """)
    }
    
    func setupConsole() throws {
        for method in ["log", "trace", "info", "warn", "error", "dir"] {
            let logger = logger
            let consoleFunc: @convention(block) () -> Void = {
                let message = JSContext.currentArguments()!.map { "\($0)"}.joined()
                logger.log("\(method): \(message)")
            }
            let console = context.objectForKeyedSubscript("console")
            console?.setObject(unsafeBitCast(consoleFunc, to: AnyObject.self), forKeyedSubscript: method as NSString)
        }
    }
    
    func setupExceptionHandler() throws {
        let logger = logger
        let handler: ((JSContext?, JSValue?) -> Void) = { context, exception in
            
            context?.exception = exception
            
            if let exception = exception,
               let stacktrace = exception.objectForKeyedSubscript("stack") {
                logger.log("error: \(exception) at \(stacktrace)")
            } else if let exception = exception {
                logger.log("error: \(exception)")
            } else {
                logger.log("error: nil")
            }
        }
        context.exceptionHandler = handler
    }
}
