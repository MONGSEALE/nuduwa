//
//  MapView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI
import MapKit
import CoreLocationUI

struct MapView: View {
    
    @StateObject private var viewModel = MapViewModel()
    @State private var locations = [Location]()
    @State var showAnnotation = false
    @State private var coordinate = CLLocationManager()
    @State private var showMessage = false
    @State private var showCreateMessage = false
    @State private var showSheet = false
    @State private var coordinateCreated = CLLocationCoordinate2D()
    @State private var sheetDismissed = false
    
   
    
    
    
    
    
    var body: some View {
        ZStack(alignment:.bottom){
            Map(coordinateRegion: $viewModel.region,showsUserLocation: true,annotationItems:locations){ item in
                MapAnnotation(coordinate: item.coordinate, content: {
                    if(sheetDismissed==false){
                        CustomMapAnnotationView(coordinate: item.coordinate)
                    }
                    else{
                        MeetingIconView(coordinate:item.coordinate)
                    }
                })
            }
            .edgesIgnoringSafeArea(.top)
            .accentColor(Color(.systemPink))
            .onAppear{
                viewModel.checkIfLocationServicesIsEnabled()
            }
            .overlay(GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                                        // Calculate the translation in points
                            self.viewModel.region.center.latitude += Double(gesture.translation.height) / Double(geometry.size.height) * self.viewModel.region.span.latitudeDelta
                                           self.viewModel.region.center.longitude -= Double(gesture.translation.width) / Double(geometry.size.width) * self.viewModel.region.span.longitudeDelta
                                    }
                        .onEnded({ value in
                            let tapLocation = value.location
                            let tapCoordinate = coordinateFromTap(tapLocation, in: geometry, region: viewModel.region)
                            if(showAnnotation==true){
                                locations.append(Location(coordinate: tapCoordinate))
                                coordinateCreated=tapCoordinate
                            }
                        }))
            })
            VStack{
                HStack{
                    Spacer()
                    Button{
                        print(coordinateCreated)
                        if(showAnnotation==false){
                            showMessage = false
                                   showPopupMessage(duration: 3)
                            withAnimation(.spring()){
                                showAnnotation.toggle()
                            }
                           
                        }
        
                        else{
                            withAnimation(.spring()){
                                showAnnotation.toggle()
                                showMessage = false
                            }
                            if(!locations.isEmpty){
                                    locations.removeLast()
                            }
                        }
                    }label: {
                        Text(showAnnotation ? "취소" : "모임만들기")
                    }
                    .fontWeight(.bold)
                    .font(.system(size:20))
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .padding()
                }
              
                
                Spacer()
                HStack(spacing:110){
                    Spacer()
                    if(showAnnotation==true){
                        Button{
                            if(locations.isEmpty){
                               showCreatePopupMessage(duration: 3)
                            }
                            else{
                                showSheet=true
                            }
                        }label: {
                            Text("생성하기!")
                        }
                        .background(Color.white)
                        .foregroundColor(.black)
                        .font(.headline)
                        .frame(width: 90, height: 35)
                        .buttonStyle(.borderedProminent)
                        .sheet(isPresented: $showSheet){
                            MeetingSetSheetView(coordinateCreated: $coordinateCreated,onDismiss: {
                                showAnnotation = false
                                sheetDismissed = true
                            })
                        }
                    }
                    LocationButton(.currentLocation){
                        viewModel.requestAllowOnceLocationPermission()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            if showMessage {
                   VStack {
                       Spacer()
                       HStack {
                           Spacer()
                           PopupMessage()
                           Spacer()
                       }
                       Spacer()
                   }
                   .transition(.scale)
               }
            if showCreateMessage {
                   VStack {
                       Spacer()
                       HStack {
                           Spacer()
                           CreatePopupMessage()
                           Spacer()
                       }
                       Spacer()
                   }
                   .transition(.scale)
               }
        }
}
   
    
    
    func showPopupMessage(duration: TimeInterval) {
        // Show the message
        withAnimation {
            showMessage = true
        }

        // Hide the message after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                showMessage = false
            }
        }
    }
    
    func showCreatePopupMessage(duration: TimeInterval) {
        // Show the message
        withAnimation {
            showCreateMessage = true
        }

        // Hide the message after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                showCreateMessage = false
            }
        }
    }
    
    func coordinateFromTap(_ tapLocation: CGPoint, in geometry: GeometryProxy, region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        if let lastLocation = locations.last {
            // Remove the previous annotation from the map
            locations.removeLast()
            viewModel.objectWillChange.send()
        }
        let frame = geometry.frame(in: .local)
        let x = Double(tapLocation.x / frame.width) * region.span.longitudeDelta + region.center.longitude - region.span.longitudeDelta / 2
        let y = Double((frame.height - tapLocation.y) / frame.height) * region.span.latitudeDelta + region.center.latitude - region.span.latitudeDelta / 2
        return CLLocationCoordinate2D(latitude: y, longitude: x)
    }
}
  






struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}






final class MapViewModel : NSObject, ObservableObject,CLLocationManagerDelegate{

    
    @Published var region = MKCoordinateRegion(center:CLLocationCoordinate2D(latitude: 37.5665, longitude:126.9780 ),
                                                   span:MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        
    
    var locationManager : CLLocationManager?
    
    override init() {
        super.init()
        locationManager?.delegate=self
    }
    
    func requestAllowOnceLocationPermission(){
        locationManager?.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:
    [CLLocation]) {
        guard let latestLocation = locations.first else{
            return
        }
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(center:latestLocation.coordinate,span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func checkIfLocationServicesIsEnabled(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager = CLLocationManager()
            checkLocationAuthorization()
            locationManager!.delegate=self
        }
        else{
            print("permission denied")
        }
    }
    
    func checkLocationAuthorization(){
        guard let locationManager = locationManager else {return}
        
        switch locationManager.authorizationStatus{
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Your location is restricted likely due to parental controls ")
        case .denied:
            print("You have denied this app location permission. Go into settings to change it")
        case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(center:locationManager.location!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func clearMapView(){
        
    }
}


extension MKCoordinateRegion {
    var zoomLevel: Int {
        let maxZoomLevel = 20
        let zoomLevel = Int(log2(360 * Double(UIScreen.main.bounds.width) / (256 * self.span.longitudeDelta))) + 1
        return min(maxZoomLevel, max(1, zoomLevel))
    }
}

struct PopupMessage: View {
    var body: some View {
        Text("장소를 선택해주세요!")
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
    }
}

struct CreatePopupMessage: View {
    var body: some View {
        Text("장소를 반드시 선택해주세요!")
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
    }
}



