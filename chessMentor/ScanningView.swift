import SwiftUI
import AVFoundation

struct ScanningView: View {
    
    @State private var isFlashOn = false
    @State private var isCapturing = false

    
    
    //Images
    let placeholderImage = Image("IMG_4293")
    let crosshairImage = Image("Crosshairs")
    
    // Setup camera session and start capture
    func setupCamera() {
        //TODO
    }
    
    // Flash toggle
    func toggleFlash() {
        //TODO
    }
    
    //Capture Image
    func captureImage() {
        //TODO
    }
    
    func openGallery() {
        //TODO
    }
    
    var body: some View {
        ZStack {
            //TODO: Replace with camera feed
            placeholderImage
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .clipped()

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
                        openGallery()
                    }) {
                        Image(systemName: "photo.on.rectangle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(50)
                    }
                    // Capture Button
                    Button(action: {
                        captureImage()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 67, height: 67)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                        }
                    }
                    // Flash Button
                    Button(action: {
                        toggleFlash()
                    }) {
                        Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(50)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            //TODO: End session
        }
    }
}

struct ScanningView_Previews: PreviewProvider {
    static var previews: some View {
        ScanningView()
    }
}
