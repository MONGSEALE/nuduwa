//
//  MeetingInfoSheetView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/14.
//

import SwiftUI
import CoreLocation
import Firebase
import SDWebImageSwiftUI

struct MeetingInfoSheetView: View {
    
   
    
    
    var body: some View {
        VStack{
              HStack{
                  WebImage(url: Auth.auth().currentUser?.photoURL)
                      .resizable()
                      .scaledToFit()
                      .frame(width:30,height: 30)
                      .font(.headline)
                      .foregroundColor(.white)
                      .padding(6)
                      .background(.blue)
                      .clipShape(Circle())
                      Text("생성시간")
                      .font(.caption2)
                      .padding(.leading)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
              Spacer()
            Text("모임 제목")
            Text("모임 내용")
            Text("모임시간")
            Text("참여 인원")
            Button{
                
            } label: {
                Text("참여하기")
            }
          }
    }
}

struct MeetingInfoSheetView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingInfoSheetView()
    }
}

