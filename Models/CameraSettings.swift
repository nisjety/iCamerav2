//
//  CameraSettings.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 28/06/2024.
//

import Foundation

struct CameraSettings {
    enum Resolution: String, CaseIterable {
        case hd1080, hd4K
    }

    enum FrameRate: Int, CaseIterable {
        case fps24 = 24, fps30 = 30, fps60 = 60
    }

    enum Format: String, CaseIterable {
        case jpeg, heif, proRAW, h264, hevc, proRes
    }

    var resolution: Resolution
    var frameRate: FrameRate
    var format: Format
    var hdrEnabled: Bool
    var nightModeEnabled: Bool
    var cinematicModeEnabled: Bool
    var stabilizationMode: StabilizationMode
    var macroModeEnabled: Bool
    var flashMode: FlashMode
    var trueToneFlashSettings: TrueToneFlashSettings
    var microphoneLevel: Float
    var audioFormat: AudioFormat
    var saveLocation: SaveLocation
    var accessibilityOptions: AccessibilityOptions
}

struct TrueToneFlashSettings {
    var intensity: Float
    var colorTemperature: Float
}

enum StabilizationMode: String, CaseIterable {
    case standard, cinematic, action
}

enum FlashMode: String, CaseIterable {
    case auto, on, off
}

enum AudioFormat: String, CaseIterable {
    case stereo, mono
}

enum SaveLocation: String, CaseIterable {
    case internal, external
}

struct AccessibilityOptions {
    var voiceOverEnabled: Bool
    var hapticFeedbackIntensity: Float
}
