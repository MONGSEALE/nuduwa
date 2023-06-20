//
//  SlideOverView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/05/02.
//

import SwiftUI

struct SlideOverView<Content: View>: View {
    @Binding var isPresented: Bool
    var content: Content
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                            print("good")
                        }
                    }
                
                content
                    .frame(width: UIScreen.main.bounds.width * 0.8,height: UIScreen.main.bounds.height * 0.9)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.trailing)
                    .offset(x: isPresented ? UIScreen.main.bounds.width * 0.2 : UIScreen.main.bounds.width)
                    
            }
        }
    }
}

extension View {
    func slideOverView(isPresented: Binding<Bool>) -> some View {
        SlideOverView(isPresented: isPresented, content: self)
    }
}
