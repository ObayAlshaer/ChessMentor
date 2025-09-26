import SwiftUI

struct ResultsView: View {
    @ObservedObject var camera: CameraModel
    
    var body: some View {
        VStack {
            Text("Results Displayed Here")
            if let capturedPhoto = camera.capturedPhoto {
                Image(uiImage: capturedPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Uhhh, idek how u are able to see this")
            }
        }
        //When leaving results, clear state so Back shows live camera
        .onDisappear {
            camera.retakePicture()
        }
    }
}

#Preview {
    ResultsView(camera: CameraModel.mock())
}
