

import Foundation

/// Encapsulates a global event monitor plus a list of handlers to call
/// for monitored events.
///
/// To use this type, create an instance, call the various "handle" methods
/// to register event handlers, then call `start()`. The tap is released
/// when this instance is deallocated. See `start()` for more details.
///
/// (This only supports "passive" taps; it can't rewrite/filter events,
/// only monitor them.)
///
public final class EventMonitor {
    public init() {
    }

    /// Registers a handler for events of the given types.
    ///
    /// It's okay to handle the same type in multiple handlers; they all
    /// get called.
    ///
    public func handle(_ eventTypes: Set<CGEventType>, with fn: @escaping (CGEvent) -> Void) {
        assert(port == nil, "Handlers must be registered before calling start()")

        handlers.append((eventTypes, fn))
    }

    /// Registers a handler for events of the given type.
    ///
    /// It's okay to handle the same type in multiple handlers; they all
    /// get called.
    ///
    public func handle(_ eventType: CGEventType, with fn: @escaping (CGEvent) -> Void) {
        handle([eventType], with: fn)
    }

    /// Convenience method which registers a handler for keyDown events
    /// which decodes the typed character for you.
    ///
    public func handleKeyDown(with fn: @escaping (String, CGEventFlags) -> Void) {
        handle([.keyDown]) { event in
            var len: Int = 0
            event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &len, unicodeString: nil)
            if len == 0 {
                return
            }
            var cdata = [UniChar](repeating: 0, count: len)
            event.keyboardGetUnicodeString(maxStringLength: len, actualStringLength: &len, unicodeString: &cdata)
            fn(String(utf16CodeUnits: cdata, count: len), event.flags)
        }
    }

    /// Creates and starts up the event monitor.
    ///
    /// Notes:
    /// - The tap is registered on the given runloop (defaulting to
    ///   the current thread's runloop); events will only be handled
    ///   while that runloop is running.
    /// - The event tap shuts down when this instance deinits.
    /// - If you haven't registered any handlers, this is a no-op.
    /// - If the user has not been prompted before, this will cause
    ///   the permissions prompt which asks them to grant permissions
    ///   in System Preferences.
    /// - If the user has denied permissions, this throws an error.
    ///
    public func start(on runLoop: RunLoop = .current) throws {
        assert(port == nil, "start() was called twice on the same instance")
        if port != nil {
            return
        }

        let eventTypes: Set<CGEventType>
            = handlers.map(\.0).reduce(Set()) { a, b in a.union(b) }

        if eventTypes.isEmpty {
            return
        }

        let mask: CGEventMask
            = eventTypes.reduce(0) { mask, type in mask | (1 << type.rawValue) }

        // Note: pass `self` unretained, to avoid a retain cycle; `port` will
        // be released and shut down when I deinit.
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { (_: CGEventTapProxy, _: CGEventType, _ event: CGEvent, _ userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in
                let myself = Unmanaged<EventMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
                myself.callback(event: event)
                return nil
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw FailedToCreateTap()
        }

        guard CGEvent.tapIsEnabled(tap: port) else {
            throw FailedToCreateTap()
        }

        runLoop.add(port, forMode: .default)
        self.port = port
    }

    /// The only kind of error that `start()` will throw. No payload.
    ///
    public struct FailedToCreateTap: Error { }

    deinit {
        CFMachPortInvalidate(port)
    }

    private func callback(event: CGEvent) {
        for (etypes, handler) in handlers {
            if etypes.contains(event.type) {
                handler(event)
            }
        }
    }

    private var handlers: [(Set<CGEventType>, (CGEvent) -> Void)] = []
    private var port: CFMachPort?
}
