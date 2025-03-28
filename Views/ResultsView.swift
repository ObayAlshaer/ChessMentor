//
//  SwiftUIView.swift
//  chessMentor
//
//  Created by Justin Bushfield on 2025-03-28.
//

import SwiftUI

struct ResultsView: View {
    
    @ObservedObject var camera: CameraModel
    
    var body: some View {
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
}

#Preview {
    ResultsView(camera: CameraModel.mock())
}
