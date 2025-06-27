import Logging

public enum ModalsLogging {
    public static let defaultLoggerLabel = "com.squareup.modals"
    public static let logger: Logging.Logger = Logger(label: ModalsLogging.defaultLoggerLabel)
}

extension Logger {
    @inlinable
    func log(
        level: Logger.Level,
        _ message: @autoclosure () -> Logger.Message,
        event: @autoclosure () -> ModalPresentationWillTransitionLogEvent,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(
            level: level,
            message(),
            metadata: event().metadata,
            source: nil,
            file: file,
            function: function,
            line: line
        )
    }
}
