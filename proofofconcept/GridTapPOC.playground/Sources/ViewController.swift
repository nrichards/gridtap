import Cocoa

class Haptic: NSObject {
    static func tap() {
        NSHapticFeedbackManager.defaultPerformer.perform(NSHapticFeedbackManager.FeedbackPattern.alignment, performanceTime: NSHapticFeedbackManager.PerformanceTime.default)
    }
}
