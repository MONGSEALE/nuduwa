//
//  Splash.swift
//  GatherUp
//
//  Created by jeon youngjoon on 2023/04/12.
//

import SwiftUI

struct Splash: View {
    var body: some View {
        ZStack(alignment: .center){
            LinearGradient(gradient: Gradient(colors: [Color(UIColor.blue), Color(UIColor.orange)]),
                           startPoint: .top, endPoint: .bottom)
            .edgesIgnoringSafeArea(.all)
            
            Text("Welcome to Nuduwa")
                .font(.title)
                .foregroundColor(.white)
            
        }
    }
}

struct Splash_Previews: PreviewProvider {
    static var previews: some View {
        Splash()
    }
}
