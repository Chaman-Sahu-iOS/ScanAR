//
//  ContentView.swift
//  ScanAR
//
//  Created by Chaman on 16/05/24.
//

import SwiftUI
import ARKit
import RealityKit

struct ContentView: View {
    @StateObject private var model = CameraViewModel()
    @State private var showingQuickLook = false
    @State private var showCameraView = false
    @State private var modelPath: String = ""
    
    let fileManager = MyFileManager()
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: CameraView(
                    model: model,
                    doneButtonView: {
                        CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint) // Ending Point
                        // Load USDZ View & Generate Model
                        return AnyView(USDZView(captureURL: self.model.captureDir))
                    }
                )
                    .navigationBarHidden(true) // Hide navigation bar in CameraView
                               , isActive: $showCameraView) {
                    EmptyView()
                }
                
                Button(action: {
                    CustomLocationManager.shared.startUpdatingLocation(for: .startingPoint)
                    showCameraView = true
                }) {
                    Text("Scan")
                        .foregroundColor(.white)
                        .frame(width: 150, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
                
                Button(action: {
                    show3DModel()
                }) {
                    Text("View 3D Model")
                        .foregroundColor(.white)
                        .frame(width: 150, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showingQuickLook) {
                    let modeldir = fileManager.modelDirectoryURL
                    let usdzUrl = modeldir.appendingPathComponent("model-mobile.usdz")
                    QuickLookPreviewController(url: URL(fileURLWithPath: usdzUrl.relativePath), isPresented: $showingQuickLook)
                }
                .onAppear(perform: {
                    self.setCaptureSettings()
                })
            }
        }
    }
    
    func setCaptureSettings() {
        // Update Catpure Mode
        /// To increase & decrease speed of capture change everySecs value
        model.captureMode = .automatic(everySecs: 1)
        
        // Minimum Capture count to create model
        CameraViewModel.recommendedMinPhotos = 25
        
        // Request for location access
        CustomLocationManager.shared.requestLocationAccess()
    }
    
    func show3DModel() {
        
        let modeldir = fileManager.modelDirectoryURL
        let usdzUrl = modeldir.appendingPathComponent("model-mobile.usdz")
        
        if fileManager.fileExists(atPath: usdzUrl.relativePath)  {
            self.modelPath = usdzUrl.relativePath
            self.showingQuickLook = true
        } else {
            let alert = UIAlertController(title: "", message: "Please Scan first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
}


#Preview {
    ContentView()
}
