//
//  DataTypes.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 26/06/2024.
//

import AVFoundation
import CoreGraphics

// MARK: - Supporting types

/// An enumeration that describes the current status of the camera.
enum CameraStatus {
    case unknown        // The initial status upon creation.
    case unauthorized   // Access to the camera or microphone is not authorized.
    case failed         // The camera failed to initialize.
    case running        // The camera is successfully running.
    case interrupted    // The camera operation is interrupted by higher-priority processes.
    case configuring    // The camera is configuring for changes in settings or modes.
    case ready          // The camera is ready to capture photos or videos.
}

/// Defines the activity states of the capture service for UI feedback.
enum CaptureActivity {
    case idle
    case photoCapture(willCapture: Bool = false, isLivePhoto: Bool = false)
    case movieCapture(duration: TimeInterval = 0.0)

    var isLivePhoto: Bool {
        if case .photoCapture(_, let isLivePhoto) = self { return isLivePhoto }
        return false
    }
    
    var willCapture: Bool {
        if case .photoCapture(let willCapture, _) = self { return willCapture }
        return false
    }
    
    var currentTime: TimeInterval {
        if case .movieCapture(let duration) = self { return duration }
        return .zero
    }
    
    var isRecording: Bool {
        if case .movieCapture(_) = self { return true }
        return false
    }
}

/// An enumeration of the camera's supported capture modes.
enum CaptureMode: String, Identifiable, CaseIterable {
    case photo = "camera.fill"
    case video = "video.fill"
    var id: Self { self }
}

/// Represents a captured photo.
struct Photo: Sendable {
    let data: Data
    let isProxy: Bool
    let livePhotoMovieURL: URL?
}

/// Represents a captured movie.
struct Movie: Sendable {
    let url: URL  // The temporary location of the file on disk.
}

/// Manages enabled photo features.
@Observable
class PhotoFeatures {
    var isFlashEnabled = false
    var isLivePhotoEnabled = false
    var qualityPrioritization: QualityPrioritization = .quality

    var current: EnabledPhotoFeatures {
        EnabledPhotoFeatures(isFlashEnabled: isFlashEnabled,
                             isLivePhotoEnabled: isLivePhotoEnabled,
                             qualityPrioritization: qualityPrioritization)
    }
}

/// Stores the enabled photo features.
struct EnabledPhotoFeatures {
    let isFlashEnabled: Bool
    let isLivePhotoEnabled: Bool
    let qualityPrioritization: QualityPrioritization
}

/// Represents the capture capabilities of the CaptureService.
struct CaptureCapabilities {
    let isFlashSupported: Bool
    let isLivePhotoCaptureSupported: Bool
    let isHDRSupported: Bool

    static let unknown = CaptureCapabilities(isFlashSupported: false,
                                             isLivePhotoCaptureSupported: false,
                                             isHDRSupported: false)
}

/// Quality prioritization settings.
enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible {
    case speed = 1
    case balanced
    case quality
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .speed: return "Speed"
        case .balanced: return "Balanced"
        case .quality: return "Quality"
        }
    }
}

/// Common camera errors.
enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

/// Represents manual control settings for the camera.
struct ManualControls {
    var iso: Float
    var shutterSpeed: Float
    var whiteBalance: Float
    var focus: CGPoint
}

/// Represents photo save options.
struct PhotoSaveOptions {
    var format: PhotoFormat
    var quality: Float
}

/// Available photo formats.
enum PhotoFormat: String, CaseIterable {
    case jpeg
    case png
    case heif
}

/// Represents AI readiness detection results.
struct AIReadinessResult {
    var isReady: Bool
    var confidence: Float
}

/// Protocol for output services handling different types of media output.
protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

/// Extensions to handle common output service tasks.
extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    func updateConfiguration(for device: AVCaptureDevice) {}
}
