/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app's top-level view.
 */

import SwiftUI

/// This is the root view for the app.
public struct CaptureView: View {
    @ObservedObject public var model: CameraViewModel
    
    public init(model: CameraViewModel) {
        self.model = model
    }
    
    public var body: some View {
        ZStack {
            // Make the entire background black.
            Color.black.edgesIgnoringSafeArea(.all)
            CameraView(model: model)
        }
        // Force dark mode so the photos pop.
        .environment(\.colorScheme, .dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject private static var model = CameraViewModel()
    static var previews: some View {
        CaptureView(model: model)
    }
}
