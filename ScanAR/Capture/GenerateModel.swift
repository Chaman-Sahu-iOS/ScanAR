/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 RealityKit Object Creation command line tools.
 */

import ArgumentParser  // Available from Apple: https://github.com/apple/swift-argument-parser
import Foundation
import os
import RealityKit
import Metal


/// Implements the main command structure, defines the command-line arguments,
/// and specifies the main run loop.
import SwiftUI
import Combine
import CoreLocation

public struct GenerateModel {
    
    private typealias Configuration = PhotogrammetrySession.Configuration
    private typealias Request = PhotogrammetrySession.Request
    
    // The local input file folder of images
    public var inputFolder: URL?
    
    // Full path to the USDZ output file
    public var outputFilename: String = ""
    
    private var detail: Request.Detail? = .reduced
    private var sampleOrdering: Configuration.SampleOrdering? = .sequential
    private var featureSensitivity: Configuration.FeatureSensitivity? = .high
    
    // Progress and error handler closures
    public var progressHandler: ((Double) -> Void)?
    public var estimatedTimeHandler: ((TimeInterval) -> Void)?
    public var errorHandler: ((String, Int) -> Void)?
    public var completionHandler: (() -> Void)?
    public var modelDirctoryHandler: ((String) -> Void)?
    
    // Initializer
   public init(inputFolder: URL?) {
        self.inputFolder = inputFolder
    }
    
    /// The main run loop entered at the end of the file.
    public mutating func run() {
                    
        self.createModelDirectory()
        
        guard PhotogrammetrySession.isSupported else {
            print("Object Capture is not available on this device.")
            errorHandler?("Object Capture is not available on this device.", 201)
            return
        }
        
        let inputFolderUrl = inputFolder
        var configuration = makeConfigurationFromArguments()
        configuration.isObjectMaskingEnabled = false
        print("Using configuration: \(String(describing: configuration))")
        
        // Try to create the session, or Relse return.
        var maybeSession: PhotogrammetrySession? = nil
        do {
            maybeSession = try PhotogrammetrySession(input: inputFolderUrl!,
                                                     configuration: configuration)
            print("Successfully created session.")
        } catch {
            print("Error creating session: \(String(describing: error))")
            errorHandler?("Error creating session: \(String(describing: error))", 202)
            return
        }
        guard let session = maybeSession else {
            errorHandler?("Failed to create photogrammetry session.", 203)
            return
        }
        
        // Store the progress and error handlers in local variables
        let progressHandler = self.progressHandler
        let errorHandler = self.errorHandler
        let estimatedTime = self.estimatedTimeHandler
        let completionHandler = self.completionHandler
        
        let waiter = Task {
            do {
                for try await output in session.outputs {
                    switch output {
                    case .processingComplete:
                        print("Processing is complete!")
                        completionHandler?()
                    case .requestError(let request, let error):
                        print("Request \(String(describing: request)) had an error: \(String(describing: error))")
                        errorHandler?("Request \(String(describing: request)) had an error: \(String(describing: error))", 400)
                    case .requestComplete(let request, let result):
                        GenerateModel.handleRequestComplete(request: request, result: result)
                    case .requestProgress(let request, let fractionComplete):
                        GenerateModel.handleRequestProgress(request: request, fractionComplete: fractionComplete)
                        // Call the progress handler with the current progress
                        progressHandler?(fractionComplete)
                    case .inputComplete:
                        print("Data ingestion is complete. Beginning processing...")
                    case .invalidSample(let id, let reason):
                        print("Invalid Sample! id=\(id) reason=\"\(reason)\"")
                        errorHandler?("Invalid Sample! id=\(id) reason=\"\(reason)\"", 401)
                    case .skippedSample(let id):
                        print("Sample id=\(id) was skipped by processing.")
                    case .automaticDownsampling:
                        print("Automatic downsampling was applied!")
                    case .processingCancelled:
                        print("Processing was cancelled.")
                        errorHandler?("Processing was cancelled.", 402)
                    case .requestProgressInfo(_, let progressInfo):
                        print("Progress Request Received. Time remaining: \(progressInfo.estimatedRemainingTime?.debugDescription)")
                        estimatedTime?(progressInfo.estimatedRemainingTime ?? 0.0)
                    case .stitchingIncomplete:
                        print("Received stitching incomplete message.")
                        errorHandler?("Received stitching incomplete message.", 403)
                    @unknown default:
                        print("Output: unhandled message: \(output.localizedDescription)")
                        errorHandler?("Output: unhandled message: \(output.localizedDescription)", 404)
                    }
                }
            } catch {
                print("Output: ERROR = \(String(describing: error))")
                errorHandler?("Output: ERROR = \(String(describing: error))", 500)
            }
        }
        
        withExtendedLifetime((session, waiter)) {
            do {
                let request = makeRequestFromArguments()
                print("Using request: \(String(describing: request))")
                try session.process(requests: [ request ])
                RunLoop.main.run()
            } catch {
                print("Process got error: \(String(describing: error))")
                errorHandler?("Process got error: \(String(describing: error))", 501)
            }
        }
    }

    private func makeConfigurationFromArguments() -> PhotogrammetrySession.Configuration {
        var configuration = PhotogrammetrySession.Configuration()
        sampleOrdering.map { configuration.sampleOrdering = $0 }
        featureSensitivity.map { configuration.featureSensitivity = $0 }
        return configuration
    }
    
    private func makeRequestFromArguments() -> PhotogrammetrySession.Request {
        let outputUrl = URL(fileURLWithPath: outputFilename)
        return PhotogrammetrySession.Request.modelFile(url: outputUrl, detail: .reduced)
    }
    
    private static func handleRequestComplete(request: PhotogrammetrySession.Request,
                                              result: PhotogrammetrySession.Result) {
        print("Request complete: \(String(describing: request)) with result...")
        switch result {
        case .modelFile(let url):
            print("\tmodelFile available at url=\(url)")
        default:
            print("\tUnexpected result: \(String(describing: result))")
        }
    }
    
    private static func handleRequestProgress(request: PhotogrammetrySession.Request,
                                              fractionComplete: Double) {
        print("Progress(request = \(String(describing: request)) = \(fractionComplete)")
    }
    
    private mutating func createModelDirectory() {
        let fileManager = MyFileManager()
        let modelURL = fileManager.modelDirectoryURL
        
        if fileManager.fileExists(atPath: modelURL.relativePath) {
            do {
                // Remove the existing directory
                try fileManager.deleteFile(atPath: modelURL.relativePath)
            } catch {
                print("Failed to remove existing directory: \(error.localizedDescription)")
                // Optional: Handle the error (e.g., by calling an error handler)
                errorHandler?("Failed to remove existing directory: \(error.localizedDescription)", 102)
                return
            }
        }
        
        do {
            // Create the new directory
            try fileManager.createDirectoryAtPath(modelURL.relativePath)
        } catch {
            // Optional: Handle the error (e.g., by calling an error handler)
            errorHandler?("Failed to create directory: \(error.localizedDescription)", 101)
            return
        }
        
        let usdz = modelURL.appendingPathComponent("model-mobile.usdz")
        
        self.outputFilename = usdz.path
        self.modelDirctoryHandler?(usdz.path)
        
        print("USDZ Path: ", outputFilename)
        print("Image Path: ", inputFolder)
    }
}


// MARK: - Helper Functions / Extensions

private func handleRequestProgress(request: PhotogrammetrySession.Request,
                                   fractionComplete: Double) {
    print("Progress(request = \(String(describing: request)) = \(fractionComplete)")
}

/// Error thrown when an illegal option is specified.
private enum IllegalOption: Swift.Error {
    case invalidDetail(String)
    case invalidSampleOverlap(String)
    case invalidSampleOrdering(String)
    case invalidFeatureSensitivity(String)
}


extension PhotogrammetrySession.Request.Detail {
    init(_ detail: String) throws {
        switch detail {
//                        case "preview": self = .preview
        case "reduced": self = .reduced
            //            case "medium": self = .medium
            //            case "full": self = .full
            //            case "raw": self = .raw
        default: throw IllegalOption.invalidDetail(detail)
        }
    }
}


extension PhotogrammetrySession.Configuration.SampleOrdering {
    init(sampleOrdering: String) throws {
        if sampleOrdering == "unordered" {
            self = .unordered
        } else if sampleOrdering == "sequential" {
            self = .sequential
        } else {
            throw IllegalOption.invalidSampleOrdering(sampleOrdering)
        }
    }
    
}


extension PhotogrammetrySession.Configuration.FeatureSensitivity {
    init(featureSensitivity: String) throws {
        if featureSensitivity == "normal" {
            self = .normal
        } else if featureSensitivity == "high" {
            self = .high
        } else {
            throw IllegalOption.invalidFeatureSensitivity(featureSensitivity)
        }
    }
}

