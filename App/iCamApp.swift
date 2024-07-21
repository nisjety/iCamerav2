//
//  iCamApp.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 02/07/2024.
//

import Foundation
import os
import SwiftUI
import AVFoundation

@main
/// The AVCam app's main entry point.
struct AVCamApp: App {
    // Simulator doesn't support the AVFoundation capture APIs. Use the preview camera when running in Simulator.
    @StateObject private var camera = CameraModel()

    var body: some Scene {
        WindowGroup {
            CameraView(camera: camera)
                .statusBarHidden(true)
                .task {
                    // Ensure the app handles authorization and setup asynchronously.
                    await initializeCameraSession()
                }
                .onAppear {
                    // Handle orientation and app lifecycle events.
                    setupAppLifecycleNotifications()
                }
        }
    }

    /// Initializes the camera session with error handling.
    private func initializeCameraSession() async {
        do {
            // Start the capture pipeline; handles authorization internally.
            try await camera.start()
        } catch {
            // Log and handle errors such as lack of authorization or device incompatibility.
            logger.error("Failed to start the camera session: \(error.localizedDescription)")
        }
    }

    /// Sets up notifications for app lifecycle events that might affect the camera.
    private func setupAppLifecycleNotifications() {
        NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            logger.log("App will enter foreground: reinitializing camera.")
            Task {
                await initializeCameraSession()
            }
        }
        NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            logger.log("App did enter background: stopping camera if necessary.")
            camera.stop()
        }
    }
}

/// A global logger for the app.
let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AVCamApp")
