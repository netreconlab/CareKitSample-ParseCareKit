//
//  ContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import UIKit
import CareKit
import CareKitStore
import os.log

struct ContactView: UIViewControllerRepresentable {
    @State var storeManager = StoreManagerKey.defaultValue

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = OCKContactsListViewController(storeManager: storeManager)
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {}
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView(storeManager: Utility.createPreviewStoreManager())
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
