//
//  CareView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//
// swiftlint:disable:next line_length
// This file embeds a UIKit View Controller inside of a SwiftUI view. I used this tutorial to figure this out https://developer.apple.com/tutorials/swiftui/interfacing-with-uikit

import SwiftUI
import UIKit
import CareKit
import CareKitStore
import os.log

struct CareView: UIViewControllerRepresentable {
    @State var storeManager = StoreManagerKey.defaultValue

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = CareViewController(storeManager: storeManager)
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {}
}

struct CareView_Previews: PreviewProvider {
    static var previews: some View {
        CareView(storeManager: Utility.createPreviewStoreManager())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
