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
    
    let model = CameraViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update the time interval of Auto Capture
       // model.defaultAutomaticCaptureIntervalSecs = 1
        
        // Update Catpure Mode
        model.captureMode = .automatic(everySecs: 1)
        
        // Request for location access
        CustomLocationManager.shared.requestLocationAccess()
        
        addCaptureButton()
        
        generate3DModelButton()
    }
    
    func addCaptureButton() {
        
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
    
    func generate3DModelButton() {
        
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
        
        // Minimum Capture count to create model
        CameraViewModel.recommendedMinPhotos = 25
        
        // Create the SwiftUI view that provides the AR experience.
        var contentView =  CameraView(model: model)
        
        contentView.scanningComepletionHandler = { isCompleted in
            if isCompleted {
                CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint) // Ending Point
            }
        }
        contentView.doneButtonView = {
            AnyView(USDZView(captureURL: self.model.captureDir))
        }
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true)
    }
    
    @objc func generateModel() {
        
        CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint)
        
        let prog = USDZView(captureURL: model.captureDir)
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: prog)
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true)
    }
    
    @objc func show3DModel() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL.appendingPathComponent("Model")
        let usdz = dataPath.appendingPathComponent("model-mobile.usdz")
        
        @State var showingQuickLook = true
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: usdz.path)  {
            
            let model = QuickLookPreviewController(url: URL(fileURLWithPath: usdz.path), isPresented: $showingQuickLook)
            
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
}

