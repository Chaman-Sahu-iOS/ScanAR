//
//  ViewController.swift
//  ScanAR
//
//  Created by Chaman on 17/05/24.
//

import UIKit
import ARKit
import RealityKit
import SwiftUI
//import CSScanObject

class ViewController: UIViewController {
    
    var model: CameraViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request for location access
        CustomLocationManager.shared.requestLocationAccess()
        
        // Add Scan Button
        self.addScanButton()
        
        // Add to View 3D Model
        self.view3DModelBtn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.model = CameraViewModel()
        
        // Set Capture Settings
        self.setCaptureSettings()
    }
    
    func setCaptureSettings() {
        
        guard let model = model else {
            self.cameraErrorAlert()
            return
        }
        
        // Minimum Capture count to create model
        CameraViewModel.recommendedMinPhotos = 25
        
        // Update Catpure Mode
        /// To increase & decrease speed of capture change everySecs value
        model.captureMode = .automatic(everySecs: 1)
    }
    
    func addScanButton() {
        
        // Create and configure the button
        let button = UIButton(type: .system)
        button.setTitle("Scan", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the button to the view hierarchy
        view.addSubview(button)
        
        // Set up button constraints
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 150),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add a target-action for the button
        button.addTarget(self, action: #selector(loadContentView), for: .touchUpInside)
    }
    
    func view3DModelBtn() {
        
        // Create and configure the button
        let button = UIButton(type: .system)
        button.setTitle("View 3D Model", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the button to the view hierarchy
        view.addSubview(button)
        
        // Set up button constraints
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 150),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add a target-action for the button
        button.addTarget(self, action: #selector(show3DModel), for: .touchUpInside)
    }
    
    @objc func loadContentView() {
        
        CustomLocationManager.shared.startUpdatingLocation(for: .startingPoint)
        
        guard let model = model else {
            self.cameraErrorAlert()
            return
        }
        
        // Create the SwiftUI view that provides the AR experience.
        var contentView =  CameraView(model: model)
        
        contentView.doneButtonView = {
            CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint) // Ending Point
            
            // Load USDZ View & Generate Model
            return AnyView(USDZView(captureURL: model.captureDir))
        }
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true)
    }
    
    /*
    @objc func generateModel() {
        
        CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint)
        
        let prog = USDZView(captureURL: model.captureDir)
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: prog)
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true)
    } */
    
    @objc func show3DModel() {
    
        let fileManager = MyFileManager()

        let modeldir = fileManager.modelDirectoryURL
        let usdzUrl = modeldir.appendingPathComponent("model-mobile.usdz")
        
        @State var showingQuickLook = true
        
        if fileManager.fileExists(atPath: usdzUrl.relativePath)  {
            
            let model = QuickLookPreviewController(url: URL(fileURLWithPath: usdzUrl.relativePath), isPresented: $showingQuickLook)
            
            // Create a UIHostingController with the SwiftUI view
            let hostingController = UIHostingController(rootView: model)
            hostingController.modalPresentationStyle = .fullScreen
            
            if showingQuickLook == false { // Dismiss View
                hostingController.dismiss(animated: true)
            } else {
                self.present(hostingController, animated: true)
            }
    
        } else {
            let alert = UIAlertController(title: "", message: "Please Scan first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { _ in
                //  context.coordinator.dismissAlert()
            }))
            self.present(alert, animated: true)
        }
    }
    
    func cameraErrorAlert() {
        let alert = UIAlertController(title: "Camera Error", message: "Please restart the app for the fresh scan", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive))
        self.present(alert, animated: true)
    }
}

