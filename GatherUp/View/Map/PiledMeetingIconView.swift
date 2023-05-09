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


struct PiledMeetingIconView: View {

    @State private var showSheet = false
    
    @Binding var showAnnotation: Bool  // 모임생성할때 아이콘 클릭 안되게
    
    var meetings: [Meeting]
    
    var onLocate: (CLLocationCoordinate2D)->()
    
    @State var isClicked: Bool = false
    
    var body: some View {
        VStack(spacing:0){
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width:40,height: 40)
                .font(.headline)
                .foregroundColor(.white)
                .padding(6)
                .background(Color(.blue))
                .clipShape(Circle())
            
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
                onLocate(CLLocationCoordinate2D(latitude: meetings.last!.latitude, longitude: meetings.last!.longitude))
            }
        }
        .sheet(isPresented: $showSheet){
            PiledMeetingsListView(meetings: meetings)
                .presentationDetents([.fraction(0.3),.height(700)])
            
        }
        .scaleEffect(isClicked ? 1.7: 1.0)
    }

    
}
struct PiledMeetingsListView: View {
    let meetings: [Meeting]
    
    var body: some View {
        NavigationStack {
            ForEach(meetings) { meeting in
                NavigationLink(value: meeting){
                    PiledMeetingCardView(meeting: meeting)
                }
                Divider()
            }
            .navigationDestination(for: Meeting.self) { meeting in
                MeetingInfoSheetView(meeting:meeting)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .onAppear{
            print("meetings:\(meetings)")
        }
        .padding(15)
    }
}


