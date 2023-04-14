//
//  MeetingIconView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/05.
//

import SwiftUI
import CoreLocation
import Firebase
import SDWebImageSwiftUI


struct MeetingIconView: View {
    
    //var coordinate: CLLocationCoordinate2D?
    var hostImage: URL
    
    var body: some View {
        Button{
            MeetingInfoSheetView()
        } label: {
            VStack(spacing:0){
                WebImage(url: hostImage)
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
}

//struct MeetingIconView_Previews: PreviewProvider {
//    static var previews: some View {
//        MeetingIconView()
//    }
//}
