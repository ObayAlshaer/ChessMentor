// Models.swift
import Foundation
import CoreGraphics
import UIKit

// MARK: - Prediction

struct Prediction: Decodable, Equatable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let `class`: String
    let confidence: CGFloat?
}

// MARK: - BestMove

struct BestMove: Decodable, Equatable {
    let best_move_uci: String
    let best_move_san: String
    let evaluation: String?
}

// MARK: - AnalysisResult

struct AnalysisResult: Equatable {
    let cropped: UIImage
    let overlays: UIImage?      // detections overlay (optional)
    let fen: String
    let bestMove: BestMove
    let finalImage: UIImage     // cropped + arrow
    
    static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        return lhs.fen == rhs.fen &&
               lhs.bestMove == rhs.bestMove &&
               lhs.cropped.size == rhs.cropped.size &&
               lhs.finalImage.size == rhs.finalImage.size
    }
}


