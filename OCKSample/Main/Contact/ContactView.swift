//
//  ContactView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitStore
import os.log
import SwiftUI
import UIKit

struct ContactView: UIViewControllerRepresentable {
    @Environment(\.careStore) var careStore

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = createViewController()
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {
        guard let navigationController = uiViewController as? UINavigationController else {
            Logger.feed.error("ContactView should have been a UINavigationController")
            return
        }
        navigationController.setViewControllers([createViewController()], animated: false)
    }

    func createViewController() -> UIViewController {
        #if os(iOS)
        return OCKContactsListViewController(
            store: careStore,
            contactViewSynchronizer: OCKDetailedContactViewSynchronizer()
        )
        #else
        return UIViewController()
        #endif
    }
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView()
            .accentColor(Color(TintColorKey.defaultValue))
            .environment(\.careStore, Utility.createPreviewStore())
    }
}
