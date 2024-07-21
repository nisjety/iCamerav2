//
//  MovieCapture.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 28/06/2024.
//

import Foundation
import AVFoundation
import CoreML
import Vision
import Combine

/// An object that manages a movie capture output to record videos.
final class MovieCapture: OutputService {
    
    @Published private(set) var captureActivity: CaptureActivity = .idle
    let output = AVCaptureMovieFileOutput()
    private var movieOutput: AVCaptureMovieFileOutput { output }
    private var delegate: MovieCaptureDelegate?
    private var timerCancellable: AnyCancellable?
    private var isHDRSupported = false
    
    // Core ML model for real-time video processing
    private var videoProcessingModel: VNCoreMLModel?
    
    // Initialize with model setup
    init(model: MLModel?) {
        if let model = model {
            self.videoProcessingModel = try? VNCoreMLModel(for: model)
        }
    }
    
    // MARK: - Core Recording Functionality
    
    /// Starts recording a movie with proper configuration for HDR, stabilization, and other features.
    func startRecording() {
        guard !movieOutput.isRecording else { return }
        guard let connection = movieOutput.connection(with: .video) else {
            fatalError("Configuration error: No video connection.")
        }
        
        configureConnection(connection)
        startMonitoringDuration()
        
        delegate = MovieCaptureDelegate()
        movieOutput.startRecording(to: createOutputURL(), recordingDelegate: delegate!)
    }
    
    /// Stops recording the movie and finalizes the file.
    func stopRecording() async throws -> Movie {
        return try await withCheckedThrowingContinuation { continuation in
            delegate?.continuation = continuation
            movieOutput.stopRecording()
            stopMonitoringDuration()
        }
    }
    
    /// Configures the video connection settings for optimal recording, including HDR, ProRes, and stabilization.
    private func configureConnection(_ connection: AVCaptureConnection) {
        // Set the codec to HEVC for high efficiency.
        if movieOutput.availableVideoCodecTypes.contains(.hevc) {
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }
        
        // Enable video stabilization for smoother footage.
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        
        // Enable HDR if supported
        if isHDRSupported {
            connection.isVideoHDREnabled = true
        }

        // Configure for ProRes format if the device supports it.
        if movieOutput.availableVideoCodecTypes.contains(.proRes422) {
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.proRes422], for: connection)
        }
    }
    
    // MARK: - Monitoring and UI Interaction
    
    /// Monitors the duration of the recording session, updating the UI as needed.
    private func startMonitoringDuration() {
        captureActivity = .movieCapture()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let duration = self.movieOutput.recordedDuration.seconds
                self.captureActivity = .movieCapture(duration: duration)
            }
    }
    
    /// Stops the monitoring of the recording duration.
    private func stopMonitoringDuration() {
        timerCancellable?.cancel()
        captureActivity = .idle
    }
    
    // MARK: - Error Handling and Robustness
    
    /// Updates the capture device's configuration when changing devices or settings.
    func updateConfiguration(for device: AVCaptureDevice) {
        isHDRSupported = device.activeFormat.isVideoHDRSupported
    }
    
    // MARK: - Output Management
    
    /// Creates a URL in the temporary directory to save recorded movies.
    private func createOutputURL() -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let uuid = UUID().uuidString
        return directory.appendingPathComponent("\(uuid).mov")
    }
    
    // MARK: - Delegate and Movie creation
    
    /// A delegate class to handle the completion of movie recording sessions.
    private class MovieCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
        
        var continuation: CheckedContinuation<Movie, Error>?
        
        /// Handles the completion of a movie recording session.
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error = error {
                continuation?.resume(throwing: error)
            } else {
                continuation?.resume(returning: Movie(url: outputFileURL))
            }
        }
    }
    
    // MARK: - Real-Time Video Processing
    
    /// Applies real-time video processing using a Core ML model.
    private func applyRealTimeProcessing(to sampleBuffer: CMSampleBuffer) {
        guard let model = videoProcessingModel else { return }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNObservation] {
                // Handle results here
            }
        }
        
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:])
        try? handler.perform([request])
    }
    
    // MARK: - Dynamic Configuration Updates
    
    /// Dynamically updates recording settings based on device capabilities or user preferences.
    func dynamicConfigurationUpdates() {
        // Implementation for dynamic configuration updates
    }
}

