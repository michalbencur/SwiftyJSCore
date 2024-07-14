import Foundation
import SwiftyJSCore

final class Logger: JSLogger {
    internal var lastLog: String?

    func log(_ string: String) {
        lastLog = string
    }
}
