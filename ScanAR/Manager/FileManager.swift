//
//  FileManager.swift
//  ScanAR
//
//  Created by Chaman on 17/05/24.
//

import Foundation

enum MyFileManagerError: Error {
    case directoryCreationFailed
    case fileNotFound
    case deletionFailed
}

class MyFileManager {
    
    let modelDirectoryURL: URL
    let fileManager = FileManager.default
    
    init() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(fileURLWithPath: documentsDirectory)
        modelDirectoryURL = docURL.appendingPathComponent("Model")
    }
    
    func createDirectoryIfNeeded() throws -> URL {
        do {
            if !fileManager.fileExists(atPath: modelDirectoryURL.path) {
                try fileManager.createDirectory(at: modelDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            return modelDirectoryURL
        } catch {
            throw MyFileManagerError.directoryCreationFailed
        }
    }
    
    func createDirectoryAtPath(_ path: String) throws {
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create directory: \(error.localizedDescription)")
            throw MyFileManagerError.directoryCreationFailed
        }
    }
    
    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    func deleteFile(atPath path: String) throws {
        if !fileManager.fileExists(atPath: path) {
            throw MyFileManagerError.fileNotFound
        }
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            throw MyFileManagerError.deletionFailed
        }
    }
}
