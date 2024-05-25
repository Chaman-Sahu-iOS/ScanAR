//
//  ContentView.swift
//  ScanAR
//
//  Created by Chaman on 16/05/24.
//

//import SwiftUI
//import RealityKit
//
//struct ContentView : View {
//    @State private var showARView = false
//
//       var body: some View {
//           VStack {
//               if showARView {
//                   ARViewContainer().edgesIgnoringSafeArea(.all)
//               } else {
//                   Text("Click the button to load AR view")
//                       .padding()
//               }
//               
//               Button(action: {
//                   showARView.toggle()
//               }) {
//                   Text(showARView ? "Hide AR View" : "Show AR View")
//                       .padding()
//                       .background(Color.blue)
//                       .foregroundColor(.white)
//                       .cornerRadius(8)
//               }
//               .padding()
//           }
//       }
//}
//
//struct ARViewContainer: UIViewRepresentable {
//    
//    func makeUIView(context: Context) -> ARView {
//        let arView = ARView(frame: .zero)
//
//        // Create a cube model
//        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
//        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
//        let model = ModelEntity(mesh: mesh, materials: [material])
//        model.transform.translation.y = 0.05
//
//        // Create horizontal plane anchor for the content
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.children.append(model)
//
//        // Add the horizontal plane anchor to the scene
//        arView.scene.anchors.append(anchor)
//
//        return arView
//    }
//    
//    func updateUIView(_ uiView: ARView, context: Context) {}
//}
//
//#Preview {
//    ContentView()
//}
