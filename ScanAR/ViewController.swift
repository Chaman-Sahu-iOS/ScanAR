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

class ViewController: UIViewController, ARSessionDelegate {
    
    var arView: ARView = {
        let view = ARView(frame: .zero)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //arView.cameraMode = .nonAR
        arView.automaticallyConfigureSession = true
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        addCaptureButton()
        
      //  self.view.addSubview(contentView)
        
//        arView.translatesAutoresizingMaskIntoConstraints = false
//        arView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//        arView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//        arView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
//        arView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
//        
//        configureARSession()
        
        
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentsDirectory = paths[0]
//        let docURL = URL(string: documentsDirectory)!
//        let dataPath = docURL.appendingPathComponent("Captures").appendingPathComponent("/")
//        
//        let fileManager = FileManager.default
//        
//        do {
//            let contents = try fileManager.contentsOfDirectory(atPath: dataPath.path)
//            print("Contents of \(dataPath):")
//            for item in contents {
//                print(item)
//            }
//        } catch {
//            print("Error reading directory contents: \(error.localizedDescription)")
//        }
//        
//        create3DModel(captureDir: dataPath)
    }
    
    func addCaptureButton() {
        
        // Create and configure the button
                let button = UIButton(type: .system)
                button.setTitle("Capture", for: .normal)
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 10
                button.translatesAutoresizingMaskIntoConstraints = false
                
                // Add the button to the view hierarchy
                view.addSubview(button)
                
                // Set up button constraints
                NSLayoutConstraint.activate([
                    button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                    button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    button.widthAnchor.constraint(equalToConstant: 150),
                    button.heightAnchor.constraint(equalToConstant: 50)
                ])
                
                // Add a target-action for the button
                button.addTarget(self, action: #selector(loadContentView), for: .touchUpInside)
    }
    
    @objc func loadContentView() {
        
        // Create the SwiftUI view that provides the AR experience.
                let contentView = ContentView()
                
                // Create a UIHostingController with the SwiftUI view
                let hostingController = UIHostingController(rootView: contentView)
                hostingController.modalPresentationStyle = .fullScreen
        
                self.present(hostingController, animated: true)
                
                // Add the hosting controller as a child to the current view controller
             //   addChild(hostingController)
                
//                // Add the hosting controller's view to the view hierarchy
//                view.addSubview(hostingController.view)
//                
//                // Configure the hosting controller's view to fit the parent view
//                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
//                    hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//                    hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                    hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//                ])
//                
//                // Notify the hosting controller that it has been moved to the parent
//                hostingController.didMove(toParent: self)
    }
    
    func create3DModel(captureDir: URL?) {
        
        var hello = HelloPhotogrammetry()
        hello.inputFolder = captureDir
        
        hello.run()
    }
    
    func configureARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = .sceneDepth // Enable scene depth
        configuration.sceneReconstruction = .meshWithClassification
        arView.session.run(configuration)
        arView.session.delegate = self
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
               // processMeshAnchor(meshAnchor)
            }
        }
    }
    
    func processMeshAnchor(_ meshAnchor: ARMeshAnchor) {
        let meshGeometry = meshAnchor.geometry
        let vertexData = extractVertices(from: meshGeometry)
        let indexData = extractIndices(from: meshGeometry)
        
        // Create the mesh descriptor
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffers.Positions(vertexData)
        meshDescriptor.primitives = .triangles(indexData)
        
        // Generate the mesh resource
        let mesh = try! MeshResource.generate(from: [meshDescriptor])
        
        // Create a model entity from the mesh
        let modelEntity = ModelEntity(mesh: mesh)
        modelEntity.model?.materials = [SimpleMaterial(color: .gray, isMetallic: false)]
        
        // Create an anchor entity and add the model entity to it
        let anchorEntity = AnchorEntity(anchor: meshAnchor)
        anchorEntity.addChild(modelEntity)
        
        // Add the anchor entity to the ARView's scene
        arView.scene.addAnchor(anchorEntity)
    }
    
    func extractVertices(from meshGeometry: ARMeshGeometry) -> [SIMD3<Float>] {
        let vertexSource = meshGeometry.vertices
        let stride = vertexSource.stride
        let buffer = vertexSource.buffer
        let count = vertexSource.count
        let offset = vertexSource.offset
        
        var vertices = [SIMD3<Float>]()
        vertices.reserveCapacity(count)
        
        for index in 0..<count {
            let vertexPointer = buffer.contents().advanced(by: offset + stride * index)
            let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
            vertices.append(vertex)
        }
        
        return vertices
    }
    func extractIndices(from meshGeometry: ARMeshGeometry) -> [UInt32] {
        let facesSource = meshGeometry.faces
        let buffer = facesSource.buffer
        let count = facesSource.count
        
        var indices = [UInt32](repeating: 0, count: count * 3)
        let indexPointer = buffer.contents().assumingMemoryBound(to: UInt32.self)
        
        for index in 0..<count {
            let face = indexPointer.advanced(by: index * 3)
            indices[index * 3] = face.pointee
            indices[index * 3 + 1] = face.advanced(by: 1).pointee
            indices[index * 3 + 2] = face.advanced(by: 2).pointee
        }
        
        return indices
    }
}

