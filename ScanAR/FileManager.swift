//
//  FileManager.swift
//  ScanAR
//
//  Created by Chaman on 17/05/24.
//

import Foundation

class MyFileManager {
    let fileManager = FileManager.default
    
    // Function to create a file
    func createFile(atPath path: String, contents: Data?, attributes: [FileAttributeKey : Any]? = nil) -> Bool {
        return fileManager.createFile(atPath: path, contents: contents, attributes: attributes)
    }
    
    // Function to delete a file
    func deleteFile(atPath path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            print("Error deleting file: \(error)")
            return false
        }
    }
    
    // Function to move a file
    func moveFile(fromPath sourcePath: String, toPath destinationPath: String) -> Bool {
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
            return true
        } catch {
            print("Error moving file: \(error)")
            return false
        }
    }
    
    // Function to read a file
    func readFile(atPath path: String) -> Data? {
        return fileManager.contents(atPath: path)
    }
    
    // Function to check if a file exists at a given path
    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
}
