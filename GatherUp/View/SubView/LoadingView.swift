//
//  LoadingView.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/27.
//

import SwiftUI

struct LoadingView: View {
    @Binding var show: Bool
    var body: some View {
        ZStack {
            if show {
                Group {
                    Rectangle()
                        .fill(.black.opacity(0.25))
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .padding(15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: show)
    }
}
//
//class LoadingIndicator {
//    static func showLoading() {
//        DispatchQueue.main.async {
//            // 최상단에 있는 window 객체 획득
//            guard let window = UIApplication.shared.windows.last else { return }
//
//            let loadingIndicatorView: UIActivityIndicatorView
//            if let existedView = window.subviews.first(where: { $0 is UIActivityIndicatorView } ) as? UIActivityIndicatorView {
//                loadingIndicatorView = existedView
//            } else {
//                loadingIndicatorView = UIActivityIndicatorView(style: .large)
//                /// 다른 UI가 눌리지 않도록 indicatorView의 크기를 full로 할당
//                loadingIndicatorView.frame = window.frame
//                loadingIndicatorView.color = .brown
//                window.addSubview(loadingIndicatorView)
//            }
//
//            loadingIndicatorView.startAnimating()
//        }
//    }
//    
//    static func hideLoading() {
//        DispatchQueue.main.async {
//            // 최상단에 있는 window 객체 획득
//            guard let window = UIApplication.shared.windows.last else { return }
//
//            let loadingIndicatorView: UIActivityIndicatorView
//            if let existedView = window.subviews.first(where: { $0 is UIActivityIndicatorView } ) as? UIActivityIndicatorView {
//                loadingIndicatorView = existedView
//            } else {
//                loadingIndicatorView = UIActivityIndicatorView(style: .large)
//                /// 다른 UI가 눌리지 않도록 indicatorView의 크기를 full로 할당
//                loadingIndicatorView.frame = window.frame
//                loadingIndicatorView.color = .brown
//                window.addSubview(loadingIndicatorView)
//            }
//
//            loadingIndicatorView.startAnimating()
//        }
//    }
//}
//
