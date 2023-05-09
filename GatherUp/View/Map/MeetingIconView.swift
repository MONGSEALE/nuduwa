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
    
    @StateObject var viewModel: FirebaseViewModel = .init()

    @State private var showSheet = false  //클릭시 시트 보이게
    @State var isClicked: Bool = false    // 클릭시 커지게
    
    @Binding var showAnnotation: Bool  // 모임생성할때 아이콘 클릭 안되게

    var meeting: Meeting
    
    var onLocate: (CLLocationCoordinate2D)->()
    
    var body: some View {
        VStack(spacing:0){
            if meeting.type == .basic {
                WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
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
                    .frame(width:40,height: 40)
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
            MeetingInfoSheetView(meeting:meeting)
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
            viewModel.fetchUser(userUID: meeting.hostUID)
        }
    }
}

