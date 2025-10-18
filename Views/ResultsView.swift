// ResultsView.swift  (replace body with this version)
import SwiftUI

struct ResultsView: View {
    @ObservedObject var camera: CameraModel

    @StateObject private var vm = ResultsViewModel(roboflowApiKey: "SxJbV6TVzYIVMe0brpAk")

    var body: some View {
        Group {
            switch vm.phase {
            case .idle:
                Text("Preparing…")
                    .onAppear {
                        if let img = camera.capturedPhoto {
                            vm.run(with: img)
                        } else {
                            vm.phase = .failed("No image")
                        }
                    }

            case .cropping:        ProgressView("Cropping board…")
            case .detecting:       ProgressView("Detecting pieces…")
            case .generatingFEN:   ProgressView("Building FEN…")
            case .queryingEngine:  ProgressView("Querying engine…")
            case .drawingArrow:    ProgressView("Drawing move…")

            case .done(let result):
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Best Move: \(result.bestMove.best_move_san) (\(result.bestMove.best_move_uci))")
                            .font(.headline)
                        Text("FEN: \(result.fen)")
                            .font(.footnote)
                            .lineLimit(2)
                            .truncationMode(.middle)

                        Image(uiImage: result.finalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .shadow(radius: 4)

//                        if let overlay = result.overlays {
//                            Text("Detections Preview")
//                                .font(.subheadline)
//                            Image(uiImage: overlay)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .cornerRadius(12)
//                        }
                    }.padding()
                }

            case .failed(let message):
                VStack(spacing: 12) {
                    Text("Analysis failed").font(.headline)
                    Text(message).font(.footnote)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // keep your existing back-reset behavior
            camera.retakePicture()
        }
    }
}
