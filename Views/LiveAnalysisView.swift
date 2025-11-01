import SwiftUI

struct LiveAnalysisView: View {
    @StateObject private var camera = LiveCaptureService()
    @StateObject private var vm = LiveAnalysisViewModel(
        detector: BoardDetectorAdapter(roboflowApiKey: "SxJbV6TVzYIVMe0brpAk"),
        engine: StockfishBestMoveProvider()
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            // Live camera
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Arrow overlay on top of the preview
            LiveArrowOverlay(arrow: vm.liveArrow)
                .ignoresSafeArea() // covers the same area as the preview

            // HUD
            VStack(spacing: 8) {
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

                HStack {
                    Button {
                        camera.stop(); vm.cancel()
                    } label: {
                        Image(systemName: "stop.circle.fill").font(.system(size: 28))
                    }
                    .padding(.horizontal)

                    Spacer()

                    if vm.isAnalyzing { ProgressView().padding(.horizontal) }
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
