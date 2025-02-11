//
//  ContentView.swift
//  chessMentor
//
//  Created by Anas Hammou on 2025-02-08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LazyVStack(alignment: .center, spacing:60){
            
            VStack (spacing: 10){
                Image("knightIcon")
            
                VStack(spacing: 20){
                    VStack(spacing:7){
                        Text("Welcome to")
                            .font(Font.custom("SFProDisplay-Bold", size: 40))
                            .fontWeight(.heavy)
                            .foregroundStyle(.white)
                        Text("Chess Mentor")
                            .font(Font.custom("SFProDisplay-Bold", size: 40))
                            .fontWeight(.heavy)
                            .foregroundStyle(Color(red: 255/255, green: 200/255, blue: 124/255, opacity: 1))
                    }
                    VStack(){
                        Text("AI-powered insights to elevate your chess game.")
                            .font(Font.custom("SFProDisplay-Regular", size: 16))
                            .foregroundStyle(.white)
                }
                }

            }
            VStack(spacing:40){
                Button("Get Started") {
                    /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                }.buttonBorderShape(.roundedRectangle)
                    .frame(width: 150, height: 50)
                    .background(
                        LinearGradient(colors: [Color(red: 193/255, green: 129/255, blue: 40/255, opacity: 1), Color(red: 255/255, green: 200/255, blue: 124/255, opacity: 1)], startPoint: .leading, endPoint: .trailing)
                        )
                    .cornerRadius(13)
                    .foregroundColor(.white)
                    .font(Font.custom("SFProDisplay-Regular", size: 24))

            }
            
            VStack(){
                Text("Learn more...")
                    .font(Font.custom("SFProDisplay-Regular", size: 17))
                    .underline()
                    .foregroundStyle(Color(red: 255/255, green: 200/255, blue: 124/255, opacity: 1))
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color(red: 46 / 255, green: 33 / 255, blue: 27 / 255, opacity: 1)
            }
            .ignoresSafeArea()

    }
    init(){
        for familyname in UIFont.familyNames {
            print(familyname)
            for fontname in UIFont.fontNames(forFamilyName: familyname) {
                print("\t\(fontname)")
            }
        }
    }
}

#Preview {
    ContentView()
}

