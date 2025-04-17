//
//  CareView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/24/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//
// This file embeds a UIKit View Controller inside of a SwiftUI view.
// Look at this tutorial for reference:
// https://developer.apple.com/tutorials/swiftui/interfacing-with-uikit

import CareKit
import CareKitStore
import SwiftUI
import UIKit

struct CareView: UIViewControllerRepresentable {

    @Environment(\.appDelegate) private var appDelegate
    @Environment(\.careStore) private var careStore

    func makeUIViewController(
        context: Context
    ) -> some UIViewController {
        let viewController = createViewController()
        let navigationController = UINavigationController(
            rootViewController: viewController
        )
        navigationController.navigationBar.backgroundColor = UIColor {
            $0.userInterfaceStyle == .light ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1): #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
        return navigationController
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        guard let navigationController = uiViewController as? UINavigationController,
              let careViewController = navigationController.viewControllers.first as? CareViewController else {
            fatalError("CareView should have been a UINavigationController")
        }
        guard careViewController.store !== careStore ||
                appDelegate?.isFirstTimeLogin == true else {
            return
        }
        let newCareViewController = createViewController()
        navigationController.setViewControllers(
            [newCareViewController],
            animated: false
        )
    }

    func createViewController() -> UIViewController {
        CareViewController(
            store: careStore
        )
    }
}

struct CareView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .environment(\.appDelegate, AppDelegate())
            .environment(\.careStore, Utility.createPreviewStore())
			.careKitStyle(Styler())
    }
}
