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

public struct CameraView: View {
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

    // Image cache to store loaded images
    @State private var imageCache = [UInt32: UIImage]()
    
    // Typealias for the closure that returns a view
    public typealias DoneButtonViewClosure = () -> AnyView
    
    // Closure property to load any view dynamically
    public var doneButtonView: DoneButtonViewClosure?
    
    public init(model: CameraViewModel, doneButtonView: DoneButtonViewClosure? = nil) {
        self.model = model
        self.doneButtonView = doneButtonView
    }
    
    public var body: some View {
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
                            .padding(.horizontal, 10)  // Adjust horizontal padding
                            .padding(.vertical, 8)     // Adjust vertical padding to be minimal
                            .padding(.bottom, 4)
                            .background(Color.black.opacity(0.4))  // Transparent background
                            .cornerRadius(8)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: model.captureFolderState?.captures.count == 0 ? 15 : 0, trailing: 30))
                        
                       // Horizontal collection view for captures
                        if let captures = model.captureFolderState?.captures, !captures.isEmpty {
                            ScrollViewReader { scrollViewProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 0) {
                                        ForEach(model.captureFolderState!.captures, id: \.id) { captureInfo in
                                            CaptureImageView(captureInfo: captureInfo, imageCache: $imageCache)
                                                .id(captureInfo.id)  // Assign a unique id for each capture
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(height: 60)
                                .onChange(of: model.captureFolderState!.captures.count) { _ in
                                    if let lastCaptureId = model.captureFolderState!.captures.last?.id {
                                        withAnimation {
                                            scrollViewProxy.scrollTo(lastCaptureId, anchor: .trailing)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 11)
                            
                        } else {
                            EmptyView() // Placeholder when there are no captures
                        }
                        
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
                        .padding(.bottom, model.captureFolderState?.captures.count == 0 ? 32 : 53)
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
                if model.captureFolderState?.captures.count ?? 0 < CameraViewModel.recommendedMinPhotos {
                    DispatchQueue.main.async {
                        self.lowCountAlert = true
                    }
                } else {
                    DispatchQueue.main.async {
                        showModelView = true  // Toggle the presentation of the model view
                    }
                }
            }) {
                Text("Done")
                    .foregroundColor(.white)
            })
            .onAppear {
                startMonitoringAcceleration()
            }
            .autoDismissAlert(isPresented: $lowCountAlert, title: "Low Capture Count", message: "Please Capture More for the Best Result", dismissAfter: 5.0)  // Use the custom modifier for auto dismiss alert
            .sheet(isPresented: $showModelView) {  // Present the new view as a sheet
                doneButtonView?()
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
        
        // Update the state variable with the current magnitude on the main thread
        DispatchQueue.main.async {
            self.accelerationMagnitude = magnitude
        }
        
        // Check if the magnitude exceeds the threshold and if the flag is not set
        if magnitude > accelerationThreshold && !isTooFast {
            DispatchQueue.main.async {
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
    }
    
    func resetMovementWarning() {
        DispatchQueue.main.async {
            isTooFast = false
            alertMoveSlow = ""
            print("Movement warning reset.")
        }
    }
}

// Separate view for displaying capture image
struct CaptureImageView: View {
    let captureInfo: CaptureInfo
    @Binding var imageCache: [UInt32: UIImage]
    
    var body: some View {
        if let cachedImage = imageCache[captureInfo.id] {
            Image(uiImage: cachedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 45, height: 60)
                .clipped()
                //.cornerRadius(8)
        } else {
            // Placeholder while loading image
            Rectangle()
                .fill(Color.gray)
                .frame(width: 45, height: 60)
               // .cornerRadius(8)
                .onAppear {
                    loadImageAsync()
                }
        }
    }
    
    private func loadImageAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = UIImage(contentsOfFile: captureInfo.imageUrl.path) {
                DispatchQueue.main.async {
                    imageCache[captureInfo.id] = image
                }
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    @StateObject private static var model = CameraViewModel()
    static var previews: some View {
        CameraView(model: model)
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

