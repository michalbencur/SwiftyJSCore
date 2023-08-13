import Foundation
import SwiftyJSCore

class Logger: JSLogger {
    var lastLog: String?

    func log(_ string: String) {
        lastLog = string
    }
}
