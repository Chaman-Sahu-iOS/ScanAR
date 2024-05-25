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

class ViewController: UIViewController, ARSessionDelegate {
    
    var arView: ARView = {
        let view = ARView(frame: .zero)
        return view
    }()
    
    let model = CameraViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.defaultAutomaticCaptureIntervalSecs = 1
        
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
        button.setTitle("Generate 3D Model", for: .normal)
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
        button.addTarget(self, action: #selector(generateModel), for: .touchUpInside)
    }
    
    @objc func loadContentView() {
        
        CustomLocationManager.shared.startUpdatingLocation(for: .startingPoint)
        
        // Create the SwiftUI view that provides the AR experience.
        let contentView =  CaptureView(model: model)
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: contentView)
        // hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true)
    }
    
    @objc func generateModel() {
        
        CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint)
        
        // Create the SwiftUI view that provides the AR experience.
        // let progressView =  ModelProgressView(model: model)
        let prog = USDZView(captureURL: model.captureDir)
        
        // Create a UIHostingController with the SwiftUI view
        let hostingController = UIHostingController(rootView: prog)
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true)
    }
}

