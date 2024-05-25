//
//  QuickLookPreviewController.swift
//  ScanAR
//
//  Created by Chaman on 23/05/24.
//

import UIKit
import UniformTypeIdentifiers
import QuickLook
import SwiftUI

struct QuickLookPreviewController: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        
        let hostingController = UIViewController()
        hostingController.view.backgroundColor = .systemBackground

        // Add a close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)  // Make the font larger
        //closeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)  // Add padding
        closeButton.addTarget(context.coordinator, action: #selector(context.coordinator.close), for: .touchUpInside)

        hostingController.view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: hostingController.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.leadingAnchor.constraint(equalTo: hostingController.view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])

        // Add the QLPreviewController as a child view controller
        hostingController.addChild(previewController)
        hostingController.view.addSubview(previewController.view)
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewController.view.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            previewController.view.leadingAnchor.constraint(equalTo: hostingController.view.leadingAnchor),
            previewController.view.trailingAnchor.constraint(equalTo: hostingController.view.trailingAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor)
        ])
        previewController.didMove(toParent: hostingController)
        
        return hostingController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: QuickLookPreviewController

        init(_ parent: QuickLookPreviewController) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }

        @objc func close() {
            parent.isPresented = false
        }
    }
}
