//
//  LocalizationLogger.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import Foundation

/// Protocol for logging localization operations
protocol LocalizationLogger: Actor {
    func log(_ message: String) async
}

struct LogEvent: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

/// Actor that broadcasts log messages to subscribers using AsyncStream
actor BroadcastLogger: LocalizationLogger {
    private var continuations: [UUID: AsyncStream<LogEvent>.Continuation] = [:]

    func log(_ message: String) async {
        let event = LogEvent(message: message)

        // Broadcast to all subscribers directly
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    /// Subscribe to log messages
    /// - Returns: A tuple with the subscription ID and an AsyncStream of log messages
    func subscribe() -> (id: UUID, stream: AsyncStream<LogEvent>) {
        let id = UUID()

        let stream = AsyncStream<LogEvent>(bufferingPolicy: .bufferingNewest(100)) { continuation in
            Task { @MainActor in
                await self.addContinuation(id: id, continuation: continuation)
            }
        }

        return (id, stream)
    }

    /// Unsubscribe from log messages
    func unsubscribe(id: UUID) async {
        if let continuation = continuations[id] {
            continuation.finish()
            continuations.removeValue(forKey: id)
        }
    }

    private func addContinuation(id: UUID, continuation: AsyncStream<LogEvent>.Continuation) {
        continuations[id] = continuation

        continuation.onTermination = { @Sendable [weak self] _ in
            Task {
                await self?.removeContinuation(id: id)
            }
        }
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
