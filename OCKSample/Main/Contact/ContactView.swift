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
    @EnvironmentObject private var appDelegate: AppDelegate

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = createViewController()
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {
        guard let navigationController = uiViewController as? UINavigationController else {
            Logger.feed.error("View should have been a UINavigationController")
            return
        }
        navigationController.setViewControllers([createViewController()], animated: false)
    }

    func createViewController() -> UIViewController {
        OCKContactsListViewController(storeManager: appDelegate.storeManager)
    }
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView()
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
