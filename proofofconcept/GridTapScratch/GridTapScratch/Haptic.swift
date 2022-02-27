import Cocoa

extension CGPoint {
    func distance(from point: CGPoint) -> CGFloat {
         return hypot(point.x - x, point.y - y)
    }
}

class Haptic: ObservableObject {
    let em: EventMonitor
    var lastLoc = CGPoint()
    let movementDelta = 30.0

    static func tap() {
        NSHapticFeedbackManager.defaultPerformer.perform(NSHapticFeedbackManager.FeedbackPattern.alignment, performanceTime: NSHapticFeedbackManager.PerformanceTime.default)
    }

    fileprivate func gridBoundaryCrossed(_ a: CGPoint, _ b: CGPoint) -> Bool {
        let ax = Int(a.x / movementDelta)
        let ay = Int(a.y / movementDelta)
        let bx = Int(b.x / movementDelta)
        let by = Int(b.y / movementDelta)

        return abs(ax - bx) != 0 || abs(ay - by) != 0
    }

    fileprivate func distanceBoundaryCrossed(_ a: CGPoint, _ b: CGPoint) -> Bool {
        return a.distance(from: b) > movementDelta
    }

    public init() {
        em = EventMonitor()
        em.handle(.mouseMoved, with: { [self] (e: CGEvent) -> Void in

            if distanceBoundaryCrossed(e.location, lastLoc) {
                Haptic.tap()
                lastLoc = e.location
            }
//
//
//            if gridBoundaryCrossed(e.location, lastLoc) {
//                Haptic.tap()
//                lastLoc = e.location
//            }
        })
        do {
            try em.start()
        } catch {
            print("Error starting input event listener: \(error)")
        }
    }
}
