import SwiftUI

protocol FirestoreDocumentConvertible {
    init?(data: [String: Any])
}

extension DocumentSnapshot {
    func data<T: FirestoreDocumentConvertible>(as type: T.Type) -> T? {
        let data = self.data()
        return data.flatMap { T(data: $0) }
    }
}
