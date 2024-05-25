//
//  ProgressView.swift
//  ScanAR
//
//  Created by Chaman on 20/05/24.
//

import SwiftUI
import CSScanObject

//@available(iOS 17.0, *)
struct ModelProgressView: View {
    @ObservedObject  var  model: CameraViewModel
    @State private var showDocumentBrowser = false
    
    init(model: CameraViewModel) {
        self.model = model
    }

    var body: some View {
        Button(
            action: {
                print("Files button clicked!")
                CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint)
                showDocumentBrowser = true
            },
            label: {
                Image(systemName: "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30)
                    .foregroundColor(.white)
            })
       // .padding(.bottom, 20)
        .padding(.trailing, 50)
        .sheet(isPresented: $showDocumentBrowser,
               onDismiss: { showDocumentBrowser = false },
               content: { USDZView(captureURL: model.captureDir) })
    }
}
