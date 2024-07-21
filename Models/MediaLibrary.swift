//
//  MediaLibrary.swift
//  iCamerav2
//
//  Created by Ima Da Costa on 26/06/2024.
//

import Foundation
import Photos
import UIKit
import CoreLocation

/// An object that writes photos and movies to the user's Photos library.
actor MediaLibrary {
    
    /// Errors that media library can throw.
    enum MediaLibraryError: Swift.Error {
        case unauthorized
        case saveFailed
        case invalidPhotoFormat
        case locationUnavailable
    }
    
    /// An asynchronous stream of thumbnail images generated after capturing media.
    let thumbnails: AsyncStream<CGImage?>
    private let continuation: AsyncStream<CGImage?>.Continuation?
    
    /// Initializes a new media library object and its thumbnail stream.
    init() {
        let (thumbnails, continuation) = AsyncStream.makeStream(of: CGImage?.self)
        self.thumbnails = thumbnails
        self.continuation = continuation
    }
    
    // MARK: - Authorization

    /// Checks if the app is authorized to access the photo library.
    private var isAuthorized: Bool {
        get async {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                isAuthorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
            }
            return isAuthorized
        }
    }

    // MARK: - Saving Media

    /// Saves a photo to the Photos library with specified options.
    /// - Parameters:
    ///   - photo: The photo object to be saved.
    ///   - options: The format and quality options for saving the photo.
    /// - Throws: `MediaLibraryError` if saving fails or the photo format is invalid.
    func save(photo: Photo, options: PhotoSaveOptions) async throws {
        let location = try await currentLocation()
        try await performChange {
            guard [.jpeg, .png, .heif].contains(options.format) else {
                throw MediaLibraryError.invalidPhotoFormat
            }
            
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: photo.isProxy ? .photoProxy : .photo, data: photo.data, options: PHAssetResourceCreationOptions())
            creationRequest.location = location
            
            if let url = photo.livePhotoMovieURL {
                let livePhotoOptions = PHAssetResourceCreationOptions()
                livePhotoOptions.shouldMoveFile = true
                creationRequest.addResource(with: .pairedVideo, fileURL: url, options: livePhotoOptions)
            }
            
            return creationRequest.placeholderForCreatedAsset
        }
    }
    
    /// Saves a movie to the Photos library.
    /// - Parameter movie: The movie object to be saved.
    /// - Throws: `MediaLibraryError` if saving fails.
    func save(movie: Movie) async throws {
        let location = try await currentLocation()
        try await performChange {
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .video, fileURL: movie.url, options: options)
            creationRequest.location = location
            return creationRequest.placeholderForCreatedAsset
        }
    }

    /// Performs a change to the user's photo library using a provided closure.
    /// - Parameter change: The closure performing the changes.
    /// - Throws: `MediaLibraryError` if the operation fails.
    private func performChange(_ change: @Sendable @escaping () -> PHObjectPlaceholder?) async throws {
        guard await isAuthorized else { throw MediaLibraryError.unauthorized }
        
        do {
            var placeholder: PHObjectPlaceholder?
            try await PHPhotoLibrary.shared().performChanges { placeholder = change() }
            
            if let placeholder {
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject else { return }
                await createThumbnail(for: asset)
            }
        } catch {
            throw MediaLibraryError.saveFailed
        }
    }
    
    // MARK: - Thumbnail Management

    /// Loads the initial thumbnail if access is authorized.
    private func loadInitialThumbnail() async {
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else { return }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        if let asset = PHAsset.fetchAssets(with: options).lastObject {
            await createThumbnail(for: asset)
        }
    }
    
    /// Creates a thumbnail for a specific asset.
    /// - Parameter asset: The asset for which to create a thumbnail.
    private func createThumbnail(for asset: PHAsset) async {
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 256, height: 256), contentMode: .default, options: nil) { [weak self] image, _ in
            guard let self = self, let image = image else { return }
            self.continuation?.yield(image.cgImage)
        }
    }
    
    // MARK: - Location Management
    
    private let locationManager = CLLocationManager()
    
    /// Retrieves the current location of the device.
    /// - Throws: `MediaLibraryError` if location cannot be determined.
    private func currentLocation() async throws -> CLLocation? {
        locationManager.requestWhenInUseAuthorization()
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.delegate = LocationDelegate(completion: { location, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let location = location {
                    continuation.resume(returning: location)
                } else {
                    continuation.resume(throwing: MediaLibraryError.locationUnavailable)
                }
            })
            locationManager.startUpdatingLocation()
        }
    }
}

/// Handles location updates.
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let completion: (CLLocation?, Error?) -> Void
    
    init(completion: @escaping (CLLocation?, Error?) -> Void) {
        self.completion = completion
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            completion(location, nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion(nil, error)
    }
}
