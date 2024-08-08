import Foundation
import SwiftyJSCore

final class Logger: JSLogger, Sendable {
    nonisolated(unsafe) var lastLog: String?

    func log(_ string: String) {
        lastLog = string
    }
}
