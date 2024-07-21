//
//  PhotoCapture.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 28/06/2024.
//


import Foundation
import AVFoundation
import CoreImage
import Vision
import CoreML

enum PhotoCaptureError: Error {
    case noPhotoData
    case configurationFailed(String)
    case unauthorizedAccess
    case visionAnalysisFailed
}

/// An object that manages a photo capture output to take photographs.
final class PhotoCapture: OutputService {
    
    @Published private(set) var captureActivity: CaptureActivity = .idle
    let output = AVCapturePhotoOutput()
    private var photoOutput: AVCapturePhotoOutput { output }
    private(set) var capabilities: CaptureCapabilities = .unknown
    private var livePhotoCount = 0

    /// Captures a photo with the specified features.
    func capturePhoto(with features: EnabledPhotoFeatures) async throws -> Photo {
        guard photoOutput.isLivePhotoCaptureSupported || features.isLivePhotoEnabled else {
            throw PhotoCaptureError.configurationFailed("Live Photo not supported on this device.")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let photoSettings = createPhotoSettings(with: features)
            let delegate = PhotoCaptureDelegate(continuation: continuation, features: features)
            monitorProgress(of: delegate)
            photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
        }
    }
    
    /// Creates the photo settings based on the specified features.
    private func createPhotoSettings(with features: EnabledPhotoFeatures) -> AVCapturePhotoSettings {
        var photoSettings = AVCapturePhotoSettings()
        
        // Set HEIF, HEVC, or ProRAW based on device capability and user preference.
        let codecType: AVVideoCodecType
        if features.enableProRAW && photoOutput.availablePhotoCodecTypes.contains(.proRAW) {
            codecType = .proRAW
        } else if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            codecType = .hevc
        } else {
            codecType = .jpeg
        }
        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: codecType])
        
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        photoSettings.flashMode = features.isFlashEnabled ? .auto : .off
        if features.isLivePhotoEnabled {
            photoSettings.livePhotoMovieFileURL = createLivePhotoURL()
        }
        photoSettings.photoQualityPrioritization = AVCapturePhotoOutput.QualityPrioritization(rawValue: features.qualityPrioritization.rawValue) ?? .balanced
        
        // Enable depth data capture if the device supports it.
        if features.enableDepthDataCapture && photoOutput.isDepthDataCaptureSupported {
            photoSettings.isDepthDataDeliveryEnabled = true
        }

        // Cinematic mode for videos within photos.
        if features.enableCinematicMode && photoOutput.availableCinematicVideoStabilizationModes.contains(.standard) {
            photoSettings.isCinematicVideoStabilizationEnabled = true
        }

        return photoSettings
    }
    
    /// Monitors the progress of the photo capture.
    private func monitorProgress(of delegate: PhotoCaptureDelegate) {
        Task {
            for await activity in delegate.activityStream {
                captureActivity = activity
            }
        }
    }
    
    /// Updates the configuration based on the given device.
    func updateConfiguration(for device: AVCaptureDevice) {
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        updateCapabilities(for: device)
    }
    
    /// Updates the capabilities based on the given device.
    private func updateCapabilities(for device: AVCaptureDevice) {
        capabilities = CaptureCapabilities(
            isFlashSupported: device.isFlashAvailable,
            isLivePhotoCaptureSupported: photoOutput.isLivePhotoCaptureSupported,
            isDepthDataCaptureSupported: photoOutput.isDepthDataCaptureSupported
        )
    }
    
    /// A delegate class that implements AVCapturePhotoCaptureDelegate
    private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        
        private let continuation: CheckedContinuation<Photo, Error>
        private let features: EnabledPhotoFeatures
        let activityStream: AsyncStream<CaptureActivity>
        private let activityContinuation: AsyncStream<CaptureActivity>.Continuation
        
        init(continuation: CheckedContinuation<Photo, Error>, features: EnabledPhotoFeatures) {
            self.continuation = continuation
            self.features = features
            let (activityStream, activityContinuation) = AsyncStream<CaptureActivity>.makeStream()
            self.activityStream = activityStream
            self.activityContinuation = activityContinuation
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard error == nil else {
                continuation.resume(throwing: error!)
                return
            }
            guard let photoData = photo.fileDataRepresentation() else {
                continuation.resume(throwing: PhotoCaptureError.noPhotoData)
                return
            }

            let processedPhoto = Photo(data: photoData, isProxy: false, livePhotoMovieURL: features.isLivePhotoEnabled ? photo.livePhotoMovieFileURL : nil)
            continuation.resume(returning: processedPhoto)
        }
    }
    
    /// Creates a URL for the live photo movie file.
    private func createLivePhotoURL() -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        return directory.appendingPathComponent("\(UUID().uuidString)_LivePhoto.mov")
    }
}
