import Logging

final class TestLogHandler: LogHandler {

    struct LogPayload {
        let level: Logger.Level
        let message: Logger.Message
        let metadata: Logger.Metadata?
        let source: String
        let file: String
        let function: String
        let line: UInt
    }

    var logs: [LogPayload] = []

    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }

    var metadata: Logging.Logger.Metadata = Logger.Metadata()

    var logLevel: Logging.Logger.Level = .info

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let payload = LogPayload(
            level: level,
            message: message,
            metadata: metadata,
            source: source,
            file: file,
            function: function,
            line: line
        )
        logs.append(payload)
    }
}
