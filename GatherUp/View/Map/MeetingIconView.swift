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
    
    @StateObject var userViewModel: UserViewModel = .init()
    @StateObject var viewModel: ProfileViewModel = .init()
    @State private var showSheet = false
    
    @Binding var showAnnotation: Bool  // 모임생성할때 아이콘 클릭 안되게

    
    var meeting: Meeting
    
    var meetings: [Meeting]?
    
    
    var onLocate: (CLLocationCoordinate2D)->()
    
    @State var isClicked: Bool = false
    
    var body: some View {
        
       /*
            Button{
                if(showAnnotation==false){
                    showSheet = true
                    onLocate(CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude))
                }
            } label: {
                VStack(spacing:0){
                    if meeting.type == .basic {
                       WebImage(url: userViewModel.user?.userImage)
                            .resizable()
                            .frame(width: 30, height: 30) // Adjust these values to resize the WebImage
                            .scaledToFit()
                            .cornerRadius(60)
                            .clipShape(Circle())
                            .padding(4) // Adjust the padding value to increase or decrease the size of the blue circle
                            .background(Circle().fill(Color.blue))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width:50,height: 50)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color(.blue))
                            .clipShape(Circle())
                    }
                    
                    
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                        .frame(width: 15,height: 15)
                        .rotationEffect(Angle(degrees: 180))
                        .offset( y : -3)
                        .padding(.bottom , 40)
                }
            }
        */ // 모임 만들기 할때 다른 모임 클릭기능 막기 위해 변경
        VStack(spacing:0){
            if meeting.type == .basic {
               WebImage(url: userViewModel.user?.userImage)
                    .resizable()
                    .frame(width: 30, height: 30) // Adjust these values to resize the WebImage
                    .scaledToFit()
                    .cornerRadius(60)
                    .clipShape(Circle())
                    .padding(4) // Adjust the padding value to increase or decrease the size of the blue circle
                    .background(Circle().fill(Color.blue))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width:50,height: 50)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color(.blue))
                    .clipShape(Circle())
            }
            
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
                .frame(width: 15,height: 15)
                .rotationEffect(Angle(degrees: 180))
                .offset( y : -3)
                .padding(.bottom , 40)
        }
        .onTapGesture {
            if(showAnnotation==false){
                showSheet = true
                onLocate(CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude))
            }
        }
        .sheet(isPresented: $showSheet){
            if meeting.type == .basic {
                MeetingInfoSheetView(meeting:meeting)
                    .presentationDetents([.fraction(0.3),.height(700)])
                    .onAppear{
                        isClicked = true
                    }
                    .onDisappear{
                        isClicked = false
                    }
            } else {
                PiledMeetingsListView(meetings: meetings!)
                    .presentationDetents([.fraction(0.3),.height(700)])
            }
        }
        .scaleEffect(isClicked ? 1.7: 1.0)
        .onAppear{
            if meeting.type == .basic{
                userViewModel.fetchUser(userUID: meeting.hostUID)
            }
        }
    }
}
struct PiledMeetingsListView: View {
    var meetings: [Meeting]
    
    var body: some View {
        NavigationStack {
            ForEach(meetings) { meeting in
                NavigationLink(value: meeting){
                    PiledMeetingCardView(meeting: meeting)
                }
            }
            .navigationDestination(for: Meeting.self) { meeting in
                MeetingInfoSheetView(meeting:meeting)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .padding(15)
    }
}


