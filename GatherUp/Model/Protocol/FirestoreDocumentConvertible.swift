import SwiftUI

protocol FirestoreConvertible {
    init?(data: [String: Any])
}

extension DocumentSnapshot {
    func data<T: FirestoreConvertible>(as type: T.Type) -> T? {
        let data = self.data()
        return data.flatMap { T(data: $0) }
    }
}
