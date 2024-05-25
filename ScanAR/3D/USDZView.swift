//
//  USDZView.swift
//  CaptureSample
//
//  Created by Chaman on 18/05/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct USDZView: View {
    
    var captureURL: URL?
    @State private var progress: Double?
    @State private var estimatedTime: String?
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    
    @State private var progressState: String = "USDZ 3D Model Generating..."
    
    @State private var startingPoint: (latitude: String, longitude: String)?
    @State private var endingPoint: (latitude: String, longitude: String)?
    
    @State private var showingQuickLook = false
    
    // Define the URL to the directory you want to open
    @State private var directoryURL: URL?
    
    var body: some View {
        NavigationView {  // Embed the view in a NavigationView
            VStack {
                Text(self.progressState)
                    .navigationTitle("3D Model")
                
                ProgressView(value: self.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                if let prog = self.progress {
                    Text("\(Int(prog * 100))%")
                        .padding()
                }
                
                if let estTime = self.estimatedTime {
                    Text("Time remaining: \(estTime)")
                        .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Display Starting Point
                if let startingPoint = startingPoint {
                    Text("Starting Point: \(startingPoint.latitude), \(startingPoint.longitude)")
                        .padding()
                } else {
                    Text("Starting Point not set")
                        .padding()
                }
                
                // Display Ending Point
                if let endingPoint = endingPoint {
                    Text("Ending Point: \(endingPoint.latitude), \(endingPoint.longitude)")
                        .padding()
                } else {
                    Text("Ending Point not set")
                        .padding()
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    self.cancelAction()
                }) {
                    Text("Cancel")
                },
                trailing: Button(action: {
                    showingQuickLook.toggle()
                }) {
                    if progressState == "File is ready to View" {
                        Text("View")
                    }
                }
            )
            .onAppear {
                startPhotogrammetry()
                fetchLocationPoints()
            }
            .sheet(isPresented: $showingQuickLook) {
                if let url = self.directoryURL {
                    QuickLookPreviewController(url: url, isPresented: $showingQuickLook)
                }
            }
        }
    }
    
    private func startPhotogrammetry() {
        DispatchQueue.global(qos: .userInitiated).async {
            var hello = HelloPhotogrammetry(inputFolder: captureURL)
            hello.progressHandler = { progress in
                DispatchQueue.main.async {
                    fetchLocationPoints()
                    self.progress = progress
                }
            }
            hello.errorHandler = { error in
                DispatchQueue.main.async {
                    self.errorMessage = error
                    self.progressState = "Something Went Wrong"
                    self.progress = nil
                    self.estimatedTime = nil
                }
            }
            hello.estimatedTimeHandler = { time in
                DispatchQueue.main.async {
                    self.estimatedTime = String(format: "%.2f", time)
                }
            }
            hello.completionHandler = {
                DispatchQueue.main.async {
                    if self.errorMessage == nil {
                        self.progressState = "File is ready to View"
                        self.estimatedTime = nil
                    }
                }
            }
            hello.modelDirctoryHandler = { path in
                DispatchQueue.main.async {
                    self.directoryURL = URL(fileURLWithPath: path)
                }
            }
            hello.run()
        }
    }
    
    private func fetchLocationPoints() {
        // Fetch the starting and ending points from the CustomLocationManager
        if let startingPoint = CustomLocationManager.shared.startingPoint {
            let dms = startingPoint.coordinate.toDMS()
            self.startingPoint = dms
        }
        
        if let endingPoint = CustomLocationManager.shared.endingPoint {
            let dms = endingPoint.coordinate.toDMS()
            self.endingPoint = dms
        }
    }
    
    private func cancelAction() {
        // Dismiss the view
        self.presentationMode.wrappedValue.dismiss()
        // Additional logic to cancel the photogrammetry process if needed
    }
}

