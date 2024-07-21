//
//  CameraView.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 26/06/2024.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraModel = CameraModel()
    
    var body: some View {
        VStack {
            CameraPreview(session: cameraModel.session)
                .onAppear {
                    cameraModel.configure()
                }
                .edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: {
                    // Capture photo action
                }) {
                    Text("Capture Photo")
                }
                Button(action: {
                    // Start/Stop video recording action
                }) {
                    Text("Record Video")
                }
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
