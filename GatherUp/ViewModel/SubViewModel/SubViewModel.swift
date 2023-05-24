//
//  SubViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI

extension ObservableObject{
//    // MARK: Error Properties
//    @Published var showError: Bool = false
//    @Published var errorMessage: String = ""
//
//    // MARK: Handling Error
//    func handleError(error: Error)async{
//        await MainActor.run(body: {
//            errorMessage = error.localizedDescription
//            showError.toggle()
//            isLoading = false
//        })
//    }
//}
//
//// MARK: Extensions
//extension UIApplication{
//    func closeKeyboard() {
//        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//    }
//
//    // Root Controller
//    func rootController() -> UIViewController {
//        guard let window = connectedScenes.first as? UIWindowScene else{return .init()}
//        guard let viewcontroller = window.windows.last?.rootViewController else{return .init()}
//
//        return viewcontroller
//    }
}

// addSnapshotListener Combine 사용 예시
/*
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift


struct FirestoreSubscription {
    // id: 리스터ID, docPath: 데이터가 있는 서버경로
    static func subscribe(id: AnyHashable, docPath: String) -> AnyPublisher<DocumentSnapshot, Never> {
        let subject = PassthroughSubject<DocumentSnapshot, Never>()
        
        let docRef = Firestore.firestore().document(docPath)
        let listener = docRef.addSnapshotListener { snapshot, _ in
            if let snapshot = snapshot {
                subject.send(snapshot)
            }
        }
        
        listeners[id] = Listener(document: docRef, listener: listener, subject: subject)
        
        return subject.eraseToAnyPublisher()
    }
    
    static func cancel(id: AnyHashable) {
        listeners[id]?.listener.remove()
        listeners[id]?.subject.send(completion: .finished)
        listeners[id] = nil
    }
}

private var listeners: [AnyHashable: Listener] = [:]
private struct Listener {
  let document: DocumentReference
  let listener: ListenerRegistration
  let subject: PassthroughSubject<DocumentSnapshot, Never>
}

import Firebase

// 데이터 타입 정하기
struct FirestoreDecoder {
    static func decode<T>(_ type: T.Type) -> (DocumentSnapshot) -> T? where T: Decodable {
        { snapshot in
            try? snapshot.data(as: type)
        }
    }
}

// Firestore에 넣을 데이터 모델
struct LabelDoc: Codable {
  let value: String?
}

import UIKit
import Combine

class ViewController: UIViewController {

  @IBOutlet weak var label: UILabel!
  
  var cancellables: Set<AnyCancellable> = []
  
  struct SubscriptionID: Hashable {}
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    FirestoreSubscription.subscribe(id: SubscriptionID(), docPath: "labels/title")
      .compactMap(FirestoreDecoder.decode(LabelDoc.self))
      .receive(on: DispatchQueue.main)
      .map(\LabelDoc.value)
      .assign(to: \.text, on: label)
      .store(in: &cancellables)
  }
}
*/