/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A view that displays the camera image and capture button.
 */
import Foundation
import SwiftUI
import CoreMotion

/// This is the app's primary view. It contains a preview area, a capture button, and a thumbnail view
/// showing the most recenty captured image.

struct CameraView: View {
    static let buttonBackingOpacity: CGFloat = 0.15
    
    @ObservedObject var model: CameraViewModel
    @State private var showInfo: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    let aspectRatio: CGFloat = 4.0 / 3.0
    let previewCornerRadius: CGFloat = 15.0
    
    let motionManager = CMMotionManager()
    @State private var lowCountAlert = false
    @State private var alertMoveSlow = ""
    @State private var captureOverlapLabel = "consecutive captures should overlap 70%"
    @State private var isTooFast = false
    @State private var timer: Timer?
    let accelerationThreshold = 1.08 // Set your threshold value here
    
    @State private var showModelView = false  // State variable to control the new view presentation
    @State private var accelerationMagnitude: Double = 0.0  // State variable to hold the acceleration magnitude
    
    var body: some View {
        NavigationView {
            GeometryReader { geometryReader in
                // Place the CameraPreviewView at the bottom of the stack.
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // Center the preview view vertically. Place a clip frame
                    // around the live preview and round the corners.
                    VStack {
                        Spacer()
                        CameraPreviewView(session: model.session)
                            .frame(width: geometryReader.size.width,
                                   height: geometryReader.size.width * aspectRatio,
                                   alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
                            .onAppear { model.startSession() }
                            .onDisappear { model.pauseSession() }
                            .overlay(
                                Image("ObjectReticle")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.all))
                        
                        Spacer()
                    }
                    
                    VStack {
                        // The app shows this view when showInfo is true.
                       // ScanToolbarView(model: model, showInfo: $showInfo).padding(.horizontal)
                        // if showInfo {
                        InfoPanelView(model: model)
                            .padding(.horizontal).padding(.top)
                        //  }
                        Spacer()
                        Text(captureOverlapLabel)
                            .foregroundColor(Color.white.opacity(0.7))
                            .padding(.horizontal, 16)  // Adjust horizontal padding
                            .padding(.vertical, 8)     // Adjust vertical padding to be minimal
                            .padding(.bottom, 10)
                            .background(Color.black.opacity(0.4))  // Transparent background
                            .cornerRadius(8)
                        CaptureButtonPanelView(model: model, width: geometryReader.size.width)
                    }
                    // Show Alert for Fast movement
                    if !alertMoveSlow.isEmpty {
                        Text(alertMoveSlow)
                            .foregroundColor(.white)
                            .padding()
                    }
                    // Acceleration Progress Indicator
                    VStack {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: [.green, .yellow, .red]),
                                                   startPoint: .bottom,
                                                   endPoint: .top)
                                )
                                .frame(width: 10)
                            
                            let clampedMagnitude = min(max(accelerationMagnitude, 0), accelerationThreshold * 2)
                            Rectangle()
                                .fill(clampedMagnitude > accelerationThreshold ? Color.red : Color.green)
                                .frame(height: (geometryReader.size.width * aspectRatio) * CGFloat(clampedMagnitude / (accelerationThreshold * 2)))
                        }
                        .cornerRadius(10)
                        .padding(.vertical, 16)
                        .padding(.bottom, 32)
                        .frame(width: 10, height: geometryReader.size.width * aspectRatio)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding()
                }
            }
            // .navigationTitle(Text("Scan"))
            // .navigationBarTitle("Scan")
            .navigationBarHidden(false)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.white)
            })
            .navigationBarItems(trailing: Button(action: {
                if model.captureFolderState!.captures.count < 30 {
                    self.lowCountAlert = true
                } else {
                    CustomLocationManager.shared.startUpdatingLocation(for: .endingPoint) // Ending Point
                    showModelView = true  // Toggle the presentation of the model view
                }
            }) {
                Text("Done")
                    .foregroundColor(.white)
            })
            .onAppear {
                startMonitoringAcceleration()
            }
            .alert(isPresented: $lowCountAlert) {
                Alert(title: Text("Low Capture Count"), message: Text("Please Capture More for the Best Result"), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showModelView) {  // Present the new view as a sheet
                USDZView(captureURL: model.captureDir)
            }
        }
    }
    
    func startMonitoringAcceleration() {
        // Check if accelerometer is available
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer is not available on this device.")
            return
        }
        
        // Set the update interval
        motionManager.accelerometerUpdateInterval = 0.05 // 10 updates per second
        
        // Start receiving accelerometer updates
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { data, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let acceleration = data?.acceleration {
                processAcceleration(acceleration)
            }
        }
    }
    
    func processAcceleration(_ acceleration: CMAcceleration) {
        // Calculate the magnitude of the acceleration vector
        let magnitude = sqrt(acceleration.x * acceleration.x +
                             acceleration.y * acceleration.y +
                             acceleration.z * acceleration.z)
        
        // Update the state variable with the current magnitude
        DispatchQueue.main.async {
            self.accelerationMagnitude = magnitude
        }
        
        // Check if the magnitude exceeds the threshold and if the flag is not set
        if magnitude > accelerationThreshold && !isTooFast {
            isTooFast = true
            alertMoveSlow = "Move slower"
            print("Movement is too fast! Magnitude: \(magnitude)")
            
            // Start a timer to reset the flag and message after a few seconds
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                resetMovementWarning()
            }
        }
    }
    
    func resetMovementWarning() {
        isTooFast = false
        alertMoveSlow = ""
        print("Movement warning reset.")
    }
}

/// This view displays the image thumbnail, capture button, and capture mode button.
struct CaptureButtonPanelView: View {
    @ObservedObject var model: CameraViewModel
    
    /// This property stores the full width of the bar. The view uses this to place items.
    var width: CGFloat
    
    var body: some View {
        // Add the bottom panel, which contains the thumbnail and capture button.
        ZStack(alignment: .center) {
            //            HStack {
            //                ThumbnailView(model: model)
            //                    .frame(width: width / 3)
            //                    .padding(.horizontal)
            //                Spacer()
            //            }
            HStack {
                Spacer()
                CaptureButton(model: model)
                Spacer()
            }
            //            HStack {
            //                Spacer()
            //                CaptureModeButton(model: model,
            //                                  frameWidth: width / 3)
            //                FilesButton(model: model)
            //                .padding(.horizontal)
            //            }
        }
    }
}

/// This is a custom "toolbar" view the app displays at the top of the screen. It includes the current capture
/// status and buttons for help and detailed information. The user can tap the entire top panel to
/// open or close the information panel.
struct ScanToolbarView: View {
    @ObservedObject var model: CameraViewModel
    @Binding var showInfo: Bool
    
    var body: some View {
        ZStack {
            HStack {
                //                SystemStatusIcon(model: model)
                //                Button(action: {
                //                    print("Pressed Info!")
                //                    withAnimation {
                //                        showInfo.toggle()
                //                    }
                //                }, label: {
                //                    Image(systemName: "info.circle").foregroundColor(Color.blue)
                //                })
                Spacer()
                NavigationLink(destination: HelpPageView()) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(Color.blue)
                }
            }
            
            //            if showInfo {
            //                Text("Current Capture Info")
            //                    .font(.caption)
            //                    .onTapGesture {
            //                        print("showInfo toggle!")
            //                        withAnimation {
            //                            showInfo.toggle()
            //                        }
            //                    }
            //            }
        }
    }
}

/// This capture button view is modeled after the Camera app button. The view changes shape when the
/// user starts shooting in automatic mode.
struct CaptureButton: View {
    static let outerDiameter: CGFloat = 80
    static let strokeWidth: CGFloat = 4
    static let innerPadding: CGFloat = 10
    static let innerDiameter: CGFloat = CaptureButton.outerDiameter -
    CaptureButton.strokeWidth - CaptureButton.innerPadding
    static let rootTwoOverTwo: CGFloat = CGFloat(2.0.squareRoot() / 2.0)
    static let squareDiameter: CGFloat = CaptureButton.innerDiameter * CaptureButton.rootTwoOverTwo -
    CaptureButton.innerPadding
    
    @ObservedObject var model: CameraViewModel
    
    init(model: CameraViewModel) {
        self.model = model
    }
    
    var body: some View {
        Button(action: {
            model.captureButtonPressed()
        }, label: {
            if model.isAutoCaptureActive {
                AutoCaptureButtonView(model: model)
            } else {
                ManualCaptureButtonView()
            }
        }).disabled(!model.isCameraAvailable || !model.readyToCapture)
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for automatic capture mode.
struct AutoCaptureButtonView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.red)
                .frame(width: CaptureButton.squareDiameter,
                       height: CaptureButton.squareDiameter,
                       alignment: .center)
                .cornerRadius(5)
            TimerView(model: model, diameter: CaptureButton.outerDiameter)
        }
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for manual capture mode.
struct ManualCaptureButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white, lineWidth: CaptureButton.strokeWidth)
                .frame(width: CaptureButton.outerDiameter,
                       height: CaptureButton.outerDiameter,
                       alignment: .center)
            Circle()
                .foregroundColor(Color.white)
                .frame(width: CaptureButton.innerDiameter,
                       height: CaptureButton.innerDiameter,
                       alignment: .center)
        }
    }
}

/*
@available(iOS 17.0, *)
struct FilesButton: View {
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
} */

struct CaptureModeButton: View {
    static let toggleDiameter = CaptureButton.outerDiameter / 3.0
    static let backingDiameter = CaptureModeButton.toggleDiameter * 2.0
    
    @ObservedObject var model: CameraViewModel
    var frameWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .center/*@END_MENU_TOKEN@*/, spacing: 2) {
            Button(action: {
                
                withAnimation {
                    model.advanceToNextCaptureMode()
                }
                
            }, label: {
                ZStack {
                    Circle()
                        .frame(width: CaptureModeButton.backingDiameter,
                               height: CaptureModeButton.backingDiameter)
                        .foregroundColor(Color.white)
                        .opacity(Double(CameraView.buttonBackingOpacity))
                    Circle()
                        .frame(width: CaptureModeButton.toggleDiameter,
                               height: CaptureModeButton.toggleDiameter)
                        .foregroundColor(Color.white)
                    switch model.captureMode {
                    case .automatic:
                        Text("A").foregroundColor(Color.black)
                            .frame(width: CaptureModeButton.toggleDiameter,
                                   height: CaptureModeButton.toggleDiameter,
                                   alignment: .center)
                    case .manual:
                        Text("M").foregroundColor(Color.black)
                            .frame(width: CaptureModeButton.toggleDiameter,
                                   height: CaptureModeButton.toggleDiameter,
                                   alignment: .center)
                    }
                }
            })
            if case .automatic = model.captureMode {
                Text("Auto Capture")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        // This frame centers the view and keeps it from reflowing when the view has a caption.
        // The view uses .top so the button won't move and the text will animate in and out.
        .frame(width: frameWidth, height: CaptureModeButton.backingDiameter, alignment: .top)
    }
}

/// This view shows a thumbnail of the last photo captured, similar to the  iPhone's Camera app. If there isn't
/// a previous photo, this view shows a placeholder.
struct ThumbnailView: View {
    private let thumbnailFrameWidth: CGFloat = 60.0
    private let thumbnailFrameHeight: CGFloat = 60.0
    private let thumbnailFrameCornerRadius: CGFloat = 10.0
    private let thumbnailStrokeWidth: CGFloat = 2
    
    @ObservedObject var model: CameraViewModel
    
    init(model: CameraViewModel) {
        self.model = model
    }
    
    var body: some View {
        NavigationLink(destination: CaptureGalleryView(model: model)) {
            if let capture = model.lastCapture {
                if let preview = capture.previewUiImage {
                    ThumbnailImageView(uiImage: preview,
                                       width: thumbnailFrameWidth,
                                       height: thumbnailFrameHeight,
                                       cornerRadius: thumbnailFrameCornerRadius,
                                       strokeWidth: thumbnailStrokeWidth)
                } else {
                    // Use full-size if no preview.
                    ThumbnailImageView(uiImage: capture.uiImage,
                                       width: thumbnailFrameWidth,
                                       height: thumbnailFrameHeight,
                                       cornerRadius: thumbnailFrameCornerRadius,
                                       strokeWidth: thumbnailStrokeWidth)
                }
            } else {  // When no image, use icon from the app bundle.
                Image(systemName: "photo.on.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
                    .frame(width: thumbnailFrameWidth, height: thumbnailFrameHeight)
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: thumbnailFrameCornerRadius)
                            .fill(Color.white)
                            .opacity(Double(CameraView.buttonBackingOpacity))
                            .frame(width: thumbnailFrameWidth,
                                   height: thumbnailFrameWidth,
                                   alignment: .center)
                    )
            }
        }
    }
}

struct ThumbnailImageView: View {
    var uiImage: UIImage
    var thumbnailFrameWidth: CGFloat
    var thumbnailFrameHeight: CGFloat
    var thumbnailFrameCornerRadius: CGFloat
    var thumbnailStrokeWidth: CGFloat
    
    init(uiImage: UIImage, width: CGFloat, height: CGFloat, cornerRadius: CGFloat,
         strokeWidth: CGFloat) {
        self.uiImage = uiImage
        self.thumbnailFrameWidth = width
        self.thumbnailFrameHeight = height
        self.thumbnailFrameCornerRadius = cornerRadius
        self.thumbnailStrokeWidth = strokeWidth
    }
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbnailFrameWidth, height: thumbnailFrameHeight)
            .cornerRadius(thumbnailFrameCornerRadius)
            .clipped()
            .overlay(RoundedRectangle(cornerRadius: thumbnailFrameCornerRadius)
                .stroke(Color.primary, lineWidth: thumbnailStrokeWidth))
            .shadow(radius: 10)
    }
}

