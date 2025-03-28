//
//  CameraModel.swift
//  chessMentor
//
//  Created by Justin Bushfield on 2025-03-28.
//

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
            
            if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                print("Using dual camera")
                device = dualCamera
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
        
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: settings, delegate: self)
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func retakePicture() {
        self.capturedPhoto = nil
        self.isTaken = false
        
        startSession()
    }
    
    func photoOutput(_ output:AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        if let photoData = photo.fileDataRepresentation() {
            self.capturedPhoto = UIImage(data: photoData)
            print("Photo captured successfully")
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

#Preview {
    ScanningView()
}
