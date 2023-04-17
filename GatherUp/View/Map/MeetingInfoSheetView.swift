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
    
 //   @ObservedObject var servermodel: FirebaseViewModel = .init()
    @EnvironmentObject var servermodel: FirebaseViewModel
    var meeting: Meeting
    
   
   

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    Capsule()
                        .frame(width: 40, height: 6)
                }
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.00001))
                
                HStack {
                    WebImage(url: meeting.hostImage)
                           .cornerRadius(60)
                    //    .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .font(.headline)
                     //   .foregroundColor(.white)
                      //  .padding(6)
                      //  .background(.blue)
                       // .clipShape(Circle())
                        
                        .padding(.leading,40)
                    VStack(alignment: .leading) {
                        Text(meeting.hostName)
                            .font(.system(size:20))
                        Text("\(meeting.publishedDate.formatted(.dateTime.hour().minute()))에 생성됨")
                            .font(.caption2)
                    }
                    .padding(.leading,50)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                Spacer()
                HStack{
                    Text(meeting.title)
                        .padding(.bottom, geometry.size.height <= 200 ? 0 : 8)
                        .font(.system(size:24))
                }
                if geometry.size.height > 310 {
                    Spacer()
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .padding(.leading,30)
                         Text(meeting.place)
                            
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "highlighter")
                            .padding(.leading,30)
                         Text(meeting.description)
                            
                        Spacer()
                    }
                    Spacer()
                    HStack{
                        Image(systemName: "calendar")
                            .padding(.leading,30)
                        Text("\(meeting.meetingDate.formatted(.dateTime.hour().minute()))에 만날꺼에요!")
                        Spacer()
                    }
                   
                    Spacer()
                    HStack{
                      //  servermodel.getMembers(meetingId: meeting.id!)
                       // print("맴버수:\(servermodel.members.count)")

                        Image(systemName: "person.2")
                            .padding(.leading,30)
                        Text("참여인원  \(servermodel.members.count)/\(meeting.numbersOfMembers+1)")
                        Spacer()
                    }
                    
                    Spacer()
                    if (Auth.auth().currentUser?.uid != meeting.hostUID){
                        Button {
                            servermodel.joinMeeting(meetingId: meeting.id!)
                        } label: {
                            Text("참여하기")
                        }
                    }
                }
            }
            .onAppear {
                servermodel.getMembers(meetingId: meeting.id!)
            }
            .onChange(of: servermodel.members) { _ in
                    //멤버 나갈시 뷰 재생성
            }
        }
    }
}




