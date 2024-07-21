//
//  DeviceLookup.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 28/06/2024.
//

import Foundation
import AVFoundation
import Combine

/// An object that retrieves camera and microphone devices, focusing on advanced sensors like LiDAR for depth perception.
final class DeviceLookup {
    
    // Discovery sessions to find the front, back, and external cameras, including depth sensors like LiDAR.
    private let frontCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let backCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let externalCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    
    init() {
        backCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera, .builtInTelephotoCamera, .builtInLiDARDepthCamera],
            mediaType: .video,
            position: .back
        )
        frontCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
        externalCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .video,
            position: .unspecified
        )
        
        // Set the user's preferred camera to the back camera if no system preference is defined.
        if AVCaptureDevice.systemPreferredCamera == nil {
            AVCaptureDevice.userPreferredCamera = backCameraDiscoverySession.devices.first
        }
    }
    
    /// Returns the system-preferred camera for the host system.
    var defaultCamera: AVCaptureDevice {
        get throws {
            guard let videoDevice = AVCaptureDevice.systemPreferredCamera else {
                throw CameraError.videoDeviceUnavailable
            }
            return videoDevice
        }
    }
    
    /// Returns the default microphone for the device on which the app runs.
    var defaultMic: AVCaptureDevice {
        get throws {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                throw CameraError.audioDeviceUnavailable
            }
            return audioDevice
        }
    }
    
    /// Returns an array of all available cameras on the device, including external cameras for iPadOS.
    var cameras: [AVCaptureDevice] {
        var cameras: [AVCaptureDevice] = []
        cameras.append(contentsOf: backCameraDiscoverySession.devices)
        cameras.append(contentsOf: frontCameraDiscoverySession.devices)
        cameras.append(contentsOf: externalCameraDiscoverySession.devices)
        
#if !targetEnvironment(simulator)
        if cameras.isEmpty {
            fatalError("No camera devices are found on this system.")
        }
#endif
        return cameras
    }
    
    /// Returns a specific camera based on the requested position.
    /// - Parameter position: The position (front or back) of the desired camera.
    /// - Throws: Throws an error if the camera is unavailable.
    func camera(at position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        let discoverySession: AVCaptureDevice.DiscoverySession
        switch position {
        case .front:
            discoverySession = frontCameraDiscoverySession
        case .back:
            discoverySession = backCameraDiscoverySession
        default:
            throw CameraError.videoDeviceUnavailable
        }
        guard let camera = discoverySession.devices.first else {
            throw CameraError.videoDeviceUnavailable
        }
        return camera
    }
    
    /// Retrieves the capabilities of a given device, providing detailed information on camera specifications.
    /// - Parameter device: The camera device.
    /// - Returns: A dictionary of the device's capabilities.
    func capabilities(for device: AVCaptureDevice) -> [String: Any] {
        var capabilities: [String: Any] = [:]
        capabilities["Max Zoom Factor"] = device.activeFormat.videoMaxZoomFactor
        capabilities["Low Light Boost Supported"] = device.isLowLightBoostSupported
        capabilities["Video Stabilization Modes"] = device.activeFormat.videoStabilizationModes
        capabilities["HDR Supported"] = device.isVideoHDREnabled
        capabilities["Photographic Styles Supported"] = device.activeFormat.photographicStylesSupported
        capabilities["Depth Data Capture Supported"] = device.isDepthDataOutputSupported
        return capabilities
    }
}
