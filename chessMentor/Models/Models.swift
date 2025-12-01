// Models.swift
import Foundation
import CoreGraphics
import UIKit

struct Prediction: Decodable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let `class`: String
    let confidence: CGFloat?   // ← add this

    // you can add confidence if Roboflow returns it
    // let confidence: CGFloat?
}

struct BestMove: Decodable {
    let best_move_uci: String
    let best_move_san: String
    let evaluation: String?
}

struct AnalysisResult {
    let cropped: UIImage
    let overlays: UIImage?      // detections overlay (optional)
    let fen: String
    let bestMove: BestMove
    let finalImage: UIImage     // cropped + arrow
}

