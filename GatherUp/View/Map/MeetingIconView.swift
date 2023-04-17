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
    
    @State private var showSheet = false
    var meeting: Meeting
    
    
    
    var body: some View {
        Button{
            showSheet = true
        } label: {
            VStack(spacing:0){
                WebImage(url: meeting.hostImage)
                    .resizable()
                    .frame(width: 30, height: 30) // Adjust these values to resize the WebImage
                    .scaledToFit()
                    .cornerRadius(60)
                    .clipShape(Circle())
                    .padding(4) // Adjust the padding value to increase or decrease the size of the blue circle
                    .background(Circle().fill(Color.blue))
                    
                
                
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
        .sheet(isPresented: $showSheet){
            MeetingInfoSheetView(meeting:meeting)
                .presentationDetents([.fraction(0.3),.height(700)])
        }
    }
}

//struct MeetingIconView_Previews: PreviewProvider {
//    static var previews: some View {
//        MeetingIconView()
//    }
//}
