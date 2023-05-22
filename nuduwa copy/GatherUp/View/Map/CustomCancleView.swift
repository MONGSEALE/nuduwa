//
//  CustomCancleView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/25.
//
import SwiftUI

struct CustomCancleView: View {
    var body: some View {
        ZStack {
                Circle()
                    .fill(Color.white) // Set the background color to white
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2) // Adjust the color and lineWidth as needed
                    )
                    .frame(width: 50, height: 50) // Adjust the frame size as needed
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold)) // Adjust the font size and weight as needed
                    .foregroundColor(Color.red) // Set the "X" color to red
            }
    }
}

struct CustomCancleView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCancleView()
    }
}

