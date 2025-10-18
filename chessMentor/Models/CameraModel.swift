import SwiftUI
import AVFoundation

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken: Bool = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var isPreviewReady: Bool = false
    @Published var capturedPhoto: UIImage? = nil
    @Published var currentPosition: AVCaptureDevice.Position = .back
    @Published var isCameraAvailable: Bool = false
    
    func check(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera Authorized")
            setup()
        case .notDetermined:
            print("Camera access not determined, requesting access...")
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Camera access granted")
                    DispatchQueue.main.async {
                        self.setup()
                    }
                } else {
                    print("Camera access denied")
                    DispatchQueue.main.async {
                        self.alert.toggle()
                    }
                }
            }
        case .denied, .restricted:
            print("Camera access denied or restricted")
            DispatchQueue.main.async {
                self.alert.toggle()
            }
        @unknown default:
            print("Unknown auth status")
            DispatchQueue.main.async {
                self.alert.toggle()
            }
        }
    }
        
    func setup(){
        do {
            self.session.beginConfiguration()
            var device: AVCaptureDevice?
            
            if let camera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                print("Using camera")
                device = camera
                isCameraAvailable = true
            } else {
                print("Failed to get the AV Capture Device")
                self.session.commitConfiguration()
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                print("Input added to session")
            } else {
                print("Cannot add input to session")
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
                print("Output added to session")
            } else {
                print("Cannot add output to session")
                self.session.commitConfiguration()
                return
            }
            
            self.session.commitConfiguration()
            print("Session configuration committed")
            
            DispatchQueue.main.async {
                self.preview = AVCaptureVideoPreviewLayer(session: self.session)
                self.preview?.videoGravity = .resizeAspectFill
                print("PreviewLayerCreated")
                self.isPreviewReady = true
            }
            
            startSession()
            
            
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            print("Camera session started")
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
            print("Camera session stopped")
        }
    }
    
    func takePicture() {
        let settings = AVCapturePhotoSettings()
        DispatchQueue.main.async {
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func retakePicture() {
        self.capturedPhoto = nil
        self.isTaken = false
        startSession()
    }
    
    //Set the image first, THEN set isTaken = true (on main).
    func photoOutput(_ output:AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation(),
              let image = UIImage(data: photoData) else {
            print("No image data")
            return
        }
        
        DispatchQueue.main.async {
            self.capturedPhoto = image    // image exists now
            self.isTaken = true           // now safe to navigate
            // (optional) self.stopSession()
            print("Photo captured successfully & navigation triggered")
        }
    }
    
    func flipCamera() {
        session.beginConfiguration()
        
        if let currentInput = session.inputs.first {
            session.removeInput(currentInput)
            
        }
        
        currentPosition = (currentPosition == .back) ? .front : .back
        
        do {
            var newDevice: AVCaptureDevice?
            
            if currentPosition == .back {
                newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            } else {
                newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            }
            
            if let device = newDevice {
                let newInput = try AVCaptureDeviceInput(device: device)
                
                if session.canAddInput(newInput){
                    session.addInput(newInput)
                } else {
                    print("Cannot add new camera input")
                }
            }
        } catch {
            print("Error switching camera: \(error.localizedDescription)")
        }
        
        session.commitConfiguration()
    }
}

extension CameraModel {
    // Mock setup for previews
    static func mock() -> CameraModel {
        let model = CameraModel()
        model.capturedPhoto = UIImage(named: "samplePhoto") // Provide a sample photo for previews
        model.isCameraAvailable = true // Simulate a camera being available
        return model
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView (context:Context) -> UIView {
        let view = UIView()
        print("Creating CameraPreview UIView")
        
        if let previewLayer = camera.preview {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            print("Preview layer added to view")
        } else {
            print("Preview layer is nil")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("Updatig CameraPreview UIView")
        DispatchQueue.main.async {
            if let previewLayer = self.camera.preview {
                previewLayer.frame = uiView.bounds
                print("Preview layer frame updated")
            } else {
                print("Preview layer is nil in updateUIView")
            }
        }
    }
}
