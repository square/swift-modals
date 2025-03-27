import UIKit


extension ToastPresentationViewController {

    func configureTimer(
        presentation: Presentation,
        behaviorPreferences: ToastBehaviorPreferences
    ) {
        let now = Date()
        var displayStartDate: Date
        if let startTime = presentation.displayStartTime {
            displayStartDate = startTime
        } else {
            displayStartDate = now
            presentation.displayStartTime = displayStartDate
        }

        switch behaviorPreferences.timedDismiss {
        case .disabled:
            presentation.autoDismissDelay = nil

        case .after(duration: let duration, onDismiss: let onDismiss):
            presentation.autoDismissDelay = duration

            let endTime = displayStartDate.addingTimeInterval(duration)

            let timer = Timer(fire: endTime, interval: 0, repeats: false) { _ in
                onDismiss()
            }

            RunLoop.main.add(timer, forMode: .common)
            presentation.autoDismissTimer = timer
        }
    }
}
