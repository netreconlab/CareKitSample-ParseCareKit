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
    private static var query: OCKEventQuery {
        var query = OCKEventQuery(for: Date())
        query.taskIDs = [TaskID.steps]
        return query
    }
    @CareStoreFetchRequest(query: query) private var events
    @EnvironmentObject private var appDelegate: AppDelegate

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = createViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.backgroundColor = UIColor { $0.userInterfaceStyle == .light ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1): #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: Context) {
        guard let navigationController = uiViewController as? UINavigationController,
              let careViewController = navigationController.viewControllers.first as? CareViewController else {
            Logger.feed.error("CareView should have been a UINavigationController")
            return
        }
        guard careViewController.store !== appDelegate.storeCoordinator else {
            // No need to replace view
            careViewController.events = events
            return
        }
        navigationController.setViewControllers([createViewController()], animated: false)
    }

    func createViewController() -> UIViewController {
        CareViewController(store: appDelegate.storeCoordinator,
                           events: events)
    }
}

struct CareView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
            .accentColor(Color(TintColorKey.defaultValue))
    }
}
