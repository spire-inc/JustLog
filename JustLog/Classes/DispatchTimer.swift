//
//  DispatchTimer.swift
//  JustLog
//
//  Created by Justice Hsiung on 6/3/18.
//  Copyright © 2018 Spire. All rights reserved.
//

import Foundation

let timerQueue = DispatchQueue(label: "com.justeat.dispatch.timer", qos: .userInitiated, target: .global(qos: .userInitiated))

public class DispatchTimer {
    private let interval: TimeInterval
    private let queue: DispatchQueue
    private let repeats: Bool

    private lazy var timer: DispatchSourceTimer? = {
        let t: DispatchSourceTimer = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + interval, repeating: repeats ? interval : .infinity, leeway: .microseconds(0))
        t.setEventHandler { [weak self] in
            self?.eventHandler?()
        }
        return t
    }()
    private var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
        case cancelled
    }

    private var state: State = .suspended

    public init(queue: DispatchQueue? = nil,
                interval: TimeInterval,
                repeats: Bool,
                handler: @escaping (() -> Void)) {
        self.queue = queue ?? timerQueue
        self.interval = interval
        self.eventHandler = handler
        self.repeats = repeats
    }
    deinit {
        timer?.setEventHandler {}
        timer?.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        timer?.resume()
        eventHandler = nil
        timer = nil
    }

    public func cancel() {
        queue.async { [weak self, weak timer] in
            guard self?.state == .suspended || self?.state == .resumed else { return }
            self?.state = .cancelled
            timer?.cancel()
        }
    }

    public func resume() {
        queue.async { [weak self, weak timer] in
            guard self?.state == .suspended || self?.state == .cancelled else { return }
            self?.state = .resumed
            timer?.resume()
        }
    }

    public func suspend() {
        queue.async { [weak self, weak timer] in
            guard self?.state == .resumed else { return }
            self?.state = .suspended
            timer?.suspend()
        }
    }
}
