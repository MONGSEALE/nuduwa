//
//  CustomMapAnnotationView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/02.
//

import SwiftUI
import MapKit  //필요없으면 삭제

struct CustomMapAnnotationView: View {
    
    
    let accentColor = Color(.red)
    
    
    var body: some View {
        VStack(spacing:0){
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width:30,height: 30)
                .font(.headline)
                .foregroundColor(.white)
                .padding(6)
                .background(accentColor)
                .clipShape(Circle())
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(accentColor)
                .frame(width: 10,height: 10)
                .rotationEffect(Angle(degrees: 180))
                .offset( y : -3)
                .padding(.bottom , 40)
        }
    }
}

struct CustomMapAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
       ZStack{
            Color.black.ignoresSafeArea()
            CustomMapAnnotationView()
        }
    }
}




