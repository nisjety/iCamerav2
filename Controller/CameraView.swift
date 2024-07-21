//
//  CameraView.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 02/07/2024.
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
struct CameraView<CameraModel: Camera>: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @StateObject var camera: CameraModel
    @State private var swipeDirection = SwipeDirection.left
    
    var body: some View {
        ZStack {
            // Manage the camera preview and interactive features.
            PreviewContainer(camera: camera) {
                CameraPreview(source: camera.previewSource)
                    .onTapGesture { location in
                        // Focus and expose at the tapped point with enhanced control.
                        Task { await camera.focusAndExpose(at: location) }
                    }
                    .simultaneousGesture(swipeGesture)
                    .opacity(camera.shouldFlashScreen ? 0.5 : 1) // Adjust opacity to reflect flash effect.
            }
            .overlay(alignment: .topLeading) {
                // Display dynamic settings based on scene recognition or AR capabilities.
                if camera.sceneRecognitionEnabled {
                    SceneRecognitionView(camera: camera)
                }
            }

            // Main camera user interface adjusted for additional controls.
            CameraUI(camera: camera, swipeDirection: $swipeDirection)
                .environment(\.cameraSettings, camera.currentSettings)
        }
        .onAppear {
            Task {
                // Handle authorization and session start.
                if await camera.isAuthorized {
                    try? await camera.start()
                }
            }
        }
        .onChange(of: verticalSizeClass) { _ in
            camera.updateConfiguration()
        }
        .onChange(of: horizontalSizeClass) { _ in
            camera.updateConfiguration()
        }
    }

    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded {
                swipeDirection = $0.translation.width < 0 ? .left : .right
                // Trigger camera mode change or feature toggle based on swipe.
                handleSwipeAction(for: swipeDirection)
            }
    }

    private func handleSwipeAction(for direction: SwipeDirection) {
        // Logic to change camera modes or toggle features.
    }
}

#Preview {
    CameraView(camera: PreviewCameraModel())
}

enum SwipeDirection {
    case left, right, up, down
}
