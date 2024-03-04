//
//  Home.swift
//  ChessMentor
//
//  Created by Mohamed-Obay Alshaer on 2024-03-04.
//

import Foundation
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to ChessMentor!")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Button(action: {
                // Action to navigate to AR chess analysis
            }) {
                Text("Start AR Chess Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                // Action to navigate to chat with AI
            }) {
                Text("Chat with AI")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

