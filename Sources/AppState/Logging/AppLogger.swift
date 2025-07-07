//
//  AppLogger.swift
//  AppState
//
//  Created by Jules on 2024-07-25.
//

import Foundation

// A simple logger for internal AppState use.
// Replace with a more robust logging solution if needed.
enum AppLogger {
    static func info(_ message: String) {
        print("[INFO] AppState: \(message)")
    }

    static func warning(_ message: String) {
        print("[WARNING] AppState: \(message)")
    }

    static func error(_ message: String) {
        print("[ERROR] AppState: \(message)")
    }
}
