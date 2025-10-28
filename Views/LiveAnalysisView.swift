import SwiftUI

struct LiveAnalysisView: View {
    @StateObject private var camera = LiveCaptureService()
    @StateObject private var vm = LiveAnalysisViewModel(
        detector: BoardDetectorAdapter(roboflowApiKey: "SxJbV6TVzYIVMe0brpAk"),
        engine: StockfishBestMoveProvider()
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            // Live camera background
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Floating overlay: live cropped board with arrow (updates continuously)
            VStack(spacing: 10) {
                if let img = vm.overlayImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 260)         // size of the overlay tile
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.15))
                        )
                        .accessibilityIdentifier("live_overlay_board")
                }

                // Status + text details
                VStack(spacing: 4) {
                    Text(vm.status)
                        .font(.footnote).bold()
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())

                    if let m = vm.bestMoveDisplay {
                        Text("Best: \(m)")
                            .font(.headline)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    if let e = vm.evaluationText {
                        Text("Eval \(e)")
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }

                // Controls
                HStack {
                    Button {
                        camera.stop()
                        vm.cancel()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 28))
                    }
                    .padding(.horizontal)

                    Spacer()

                    if vm.isAnalyzing {
                        ProgressView().padding(.horizontal)
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            camera.onFrame = { [weak vm] pb in
                Task { @MainActor in vm?.handleFrame(pb) }
            }
            camera.start()
        }
        .onDisappear {
            camera.stop()
            vm.cancel()
        }
        .navigationTitle("Live Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}
