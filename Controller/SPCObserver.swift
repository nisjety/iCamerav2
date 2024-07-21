//
//  SPCObserver.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 28/06/2024.
//

import Foundation
import AVFoundation

/// An object that provides an asynchronous stream of capture devices that represent the system-preferred camera.
class SystemPreferredCameraObserver: NSObject {
    
    private let systemPreferredKeyPath = "systemPreferredCamera"
    
    /// Holds the asynchronous stream of system-preferred camera updates.
    let changes: AsyncStream<AVCaptureDevice?>
    /// Manages continuation of the asynchronous stream.
    private var continuation: AsyncStream<AVCaptureDevice?>.Continuation?

    /// Initializes the observer and starts monitoring changes to the system-preferred camera.
    override init() {
        let (changes, continuation) = AsyncStream.makeStream(of: AVCaptureDevice?.self)
        self.changes = changes
        self.continuation = continuation
        
        super.init()
        
        /// Set up observation of the `systemPreferredCamera` class property on `AVCaptureDevice` to receive updates.
        AVCaptureDevice.self.addObserver(self, forKeyPath: systemPreferredKeyPath, options: [.new], context: nil)
    }

    /// Cleans up by removing observer and finishing the asynchronous stream upon deinitialization.
    deinit {
        AVCaptureDevice.self.removeObserver(self, forKeyPath: systemPreferredKeyPath)
        continuation?.finish()
    }
    
    /// Responds to changes in the observed system-preferred camera property.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == systemPreferredKeyPath {
            // Capture the new value of the system-preferred camera from the change dictionary.
            let newDevice = change?[.newKey] as? AVCaptureDevice
            // Pass the new device to the asynchronous stream.
            continuation?.yield(newDevice)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
