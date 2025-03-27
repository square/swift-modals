import Logging

public enum ModalsLogging {
    public static let defaultLoggerLabel = "com.squareup.modals"
    public static let logger: Logging.Logger = Logger(label: ModalsLogging.defaultLoggerLabel)
}
