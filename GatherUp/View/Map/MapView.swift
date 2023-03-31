//
//  MapView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI
import MapKit
import CoreLocationUI

import Firebase

struct MapView: View {
    
    @StateObject private var viewModel = MapViewModel()
    @State private var locations = [Meeting]()
    //@State private var locations = [Location]()
    @State var showAnnotation = true
    @State private var annotationLocationLatitude: CLLocationCoordinate2D?
    @State private var annotationLocationLongitude: CLLocationCoordinate2D?
    @State private var annotationLocation: CLLocationCoordinate2D?
    
    @StateObject var save: SaveNewMeeting = .init()
    
    var body: some View {
        ZStack(alignment:.bottom){
            
            Map(coordinateRegion: $viewModel.region,showsUserLocation: true,annotationItems:locations){ location in
                
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
            }
                .edgesIgnoringSafeArea(.top)
                .accentColor(Color(.systemPink))
                .onAppear{
                    viewModel.checkIfLocationServicesIsEnabled()
                }
            
            VStack{
                HStack{
                    Spacer()
                    Button{
                        if(showAnnotation==true){
                            /*
                            let newLocation = Location(id: UUID(), name: "New location", description: "", latitude: viewModel.region.center.latitude, longitude: viewModel.region.center.longitude)
                                locations.append(newLocation)
                             */
                            let user = Auth.auth().currentUser
                            guard
                                let userName: String = user?.displayName,
                                let userUID: String = user?.uid
                            else{return}
                            let profileURL = user?.photoURL
                            let newMeeting = Meeting(name: "모임1", description: "아무나", latitude: viewModel.region.center.latitude, longitude: viewModel.region.center.longitude, userName: userName, userUID: userUID, userImage: profileURL ?? URL(filePath: ""))
                            save.createMeeting(meeting: newMeeting)
                            locations.append(newMeeting)
                            
                            withAnimation(.spring()){
                                showAnnotation.toggle()
                            }
                        }
                        else{
                            //locations.removeLast()
                            
                            withAnimation(.spring()){
                               showAnnotation.toggle()
                            }
                        }
                        
                    }label: {
                        Text(showAnnotation ? "모임만들기" : "취소")
                    }
                    .fontWeight(.bold)
                    .font(.system(size:20))
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .padding()
                    
                }
                Spacer()
                HStack{
                    Spacer()
                    LocationButton(.currentLocation){
                          viewModel.requestAllowOnceLocationPermission()
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
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





