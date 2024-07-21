//
//  Camera.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 26/06/2024.
//

import SwiftUI
import CoreML
import Vision
import AVFoundation
import ARKit

/// A protocol that represents the model for the camera view.
///
/// The AVFoundation camera APIs require running on a physical device. The app defines the model as a protocol to make it
/// simple to swap out the real camera for a test camera when previewing SwiftUI views.
@MainActor
protocol Camera: AnyObject {
    
    /// Provides the current status of the camera.
    var status: CameraStatus { get }

    /// The camera's current activity state, which can be photo capture, movie capture, or idle.
    var captureActivity: CaptureActivity { get }

    /// The source of video content for a camera preview, which could be augmented with ARKit.
    var previewSource: PreviewSource { get }
    
    /// Starts the camera capture pipeline.
    func start() async

    /// The capture mode, which can be photo or video.
    var captureMode: CaptureMode { get set }
    
    /// Indicates whether the camera is currently switching capture modes.
    var isSwitchingModes: Bool { get }

    /// Switches between video devices available on the host system.
    func switchVideoDevices() async
    
    /// Indicates whether the camera is currently switching video devices.
    var isSwitchingVideoDevices: Bool { get }
    
    /// The photo features that a person can enable in the user interface.
    var photoFeatures: PhotoFeatures { get }

    /// Performs a one-time automatic focus and exposure operation.
    func focusAndExpose(at point: CGPoint) async
    
    /// Captures a photo and writes it to the user's photo library.
    func capturePhoto(options: PhotoSaveOptions) async
    
    /// Indicates whether to show visual feedback when capture begins.
    var shouldFlashScreen: Bool { get }
    
    /// Indicates whether the camera supports HDR video recording.
    var isHDRVideoSupported: Bool { get }
    
    /// Indicates whether camera enables HDR video recording.
    var isHDRVideoEnabled: Bool { get set }
    
    /// Starts or stops recording a movie, and writes it to the user's photo library when complete.
    func toggleRecording() async
    
    /// A thumbnail image for the most recent photo or video capture.
    var thumbnail: CGImage? { get }
    
    /// An error if the camera encountered a problem.
    var error: Error? { get }
    
    // MARK: - New Enhancements for v2

    /// Indicates whether AI readiness detection is enabled.
    var isAIReadinessDetectionEnabled: Bool { get set }
    
    /// Uses AI to detect if a person is ready for the photo based on facial expressions and body poses.
    func detectReadiness() async -> Bool
    
    /// The manual control settings for the camera.
    var manualControls: ManualControls { get set }

    /// Sets manual focus to a specific point.
    func setManualFocus(to point: CGPoint) async

    /// Sets the manual exposure value.
    func setManualExposure(to value: Float) async

    /// Sets the manual white balance.
    func setManualWhiteBalance(to value: Float) async

    /// Provides options for saving photos in different formats.
    var photoSaveOptions: PhotoSaveOptions { get set }

    // MARK: - Enhancements for iPhone 14 Pro, 15 Pro, and iOS 18

    /// Indicates whether face-driven auto focus is enabled.
    var isFaceAutoFocusEnabled: Bool { get set }

    /// Indicates whether face-driven auto exposure is enabled.
    var isFaceAutoExposureEnabled: Bool { get set }

    /// The depth data output for capturing depth information.
    var depthDataOutput: AVCaptureDepthDataOutput? { get set }

    /// Configures the depth data output for capturing depth information.
    func configureDepthDataOutput() async
    
    /// Uses TensorFlow Lite to run on-device AI models for advanced image processing.
    func runTensorFlowLiteModel(onFrame frame: UIImage) async -> [Float]?
    
    /// Enhancements to leverage ARKit for augmented reality features in the camera preview.
    func integrateARKitFeatures() async
}


/// Enum representing different camera statuses.
enum CameraStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
    case configured
    case error(Error)
}

/// Enum representing the capture activity of the camera.
enum CaptureActivity {
    case idle
    case capturingPhoto
    case capturingVideo
}

/// Enum representing the preview source of the camera.
enum PreviewSource {
    case camera
    case test
}

/// Enum representing the capture modes.
enum CaptureMode {
    case photo
    case video
}

/// Struct representing the photo features that can be enabled.
struct PhotoFeatures {
    var flashEnabled: Bool
    var livePhotosEnabled: Bool
    var timerEnabled: Bool
    // Add more features as needed
}

/// Struct representing manual controls settings.
struct ManualControls {
    var iso: Float
    var shutterSpeed: Float
    var whiteBalance: Float
    var focus: CGPoint
}

/// Struct representing photo save options.
struct PhotoSaveOptions {
    var format: PhotoFormat
    var quality: Float
}

/// Enum representing photo formats.
enum PhotoFormat {
    case jpeg
    case png
    case heif
}
