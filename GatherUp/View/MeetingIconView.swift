//
//  MeetingIconView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/05.
//

import SwiftUI
import CoreLocation


struct MeetingIconView: View {
    
    var coordinate: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(spacing:0){
            Image("몽실이")
                .resizable()
                .scaledToFit()
                .frame(width:30,height: 30)
                .font(.headline)
                .foregroundColor(.white)
                .padding(6)
                .background(.blue)
                .clipShape(Circle())
          
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
                .frame(width: 10,height: 10)
                .rotationEffect(Angle(degrees: 180))
                .offset( y : -3)
                .padding(.bottom , 40)
        }
    }
}

struct MeetingIconView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingIconView()
    }
}
