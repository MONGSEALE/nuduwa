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
    
    var meeting: Meeting
    
    
    var onLocate: (CLLocationCoordinate2D)->()
    
    @State private var isClicked: Bool = false
    
    var body: some View {
       
            Button{
                showSheet = true
                onLocate(CLLocationCoordinate2D(latitude: meeting.latitude, longitude: meeting.longitude))
            } label: {
                VStack(spacing:0){
                    WebImage(url: userViewModel.user?.userImage)
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
               
                    MeetingInfoSheetView(meeting:meeting, hostUser: userViewModel.user!/*,user: viewModel.myProfile!*/)
                        .presentationDetents([.fraction(0.3),.height(700)])
                        .onAppear{
                            isClicked = true
                        }
                        .onDisappear{
                            isClicked = false
                        }
            }
            .scaleEffect(isClicked ? 1.7: 1.0)
            .onAppear{
                userViewModel.userListener(userUID: meeting.hostUID)
            }
        
    }
}



