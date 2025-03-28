import SwiftUI
import AVFoundation

struct ScanningView: View {
    
    //Camera
    @StateObject private var camera = CameraModel()

    //Images
    let crosshairImage = Image("Crosshairs")
    
    //COLORS
    let primaryColor = Color(red: 255/255, green: 200/255, blue: 124/255)
    let accentColor = Color(red: 193/255, green: 129/255, blue: 40/255)
    let backgroundColor = Color(red: 46/255, green: 33/255, blue: 27/255)
    
    var body: some View {
        ZStack {
            if let capturedPhoto = camera.capturedPhoto {
                Image(uiImage: capturedPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            } else if camera.isPreviewReady {
                CameraPreview(camera: camera)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Loading camera...")
            }

            VStack {
                RoundedRectangle(cornerRadius: 16 )
                    .fill(Color(red: 51 / 255.0, green: 51 / 255.0, blue: 51 / 255.0).opacity(0.75))
                    .frame(width: 178, height:50)
                    .overlay(
                            Text("Find a board to scan")
                                .foregroundColor(.white)
                                .font(Font.custom("SFProDisplay-Regular", size: 16))
                        )
                    .padding(.top, 80)

                crosshairImage
                    .resizable()
                    .frame(width: 300, height: 300)
                    .padding(.top, 50)
                
                
                Spacer()
                
                // Bottom control buttons
                HStack {
                    // Gallery Button
                    Button(action: {
                        //openGallery()
                    }) {
                        Image(systemName: "photo.on.rectangle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(50)
                    }
                    // Capture Button
                    Button(action: camera.takePicture) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 67, height: 67)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                        }
                    }
                
                    NavigationLink(destination: ResultsView(camera: camera), isActive: $camera.isTaken) {
                                            EmptyView()
                                        }
                    // Flash Button
                    Button(action: {
                        //toggleFlash()
                    }) {
                        Image("bolt.slash.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(50)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            camera.check()
        }
        .alert(isPresented: $camera.alert) {
            Alert(
                title: Text("Camera access denied"),
                message: Text("Please enable camera access in settings to continue"),
                primaryButton: .default(Text("Settings"), action: {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }), secondaryButton: .cancel()
            )
        }
    }
}

struct ScanningView_Previews: PreviewProvider {
    static var previews: some View {
        ScanningView()
    }
}
