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

    @ObservedObject var viewModel = CareViewModel()

    func makeUIViewController(context: Context) -> some UIViewController {

        let view = CareViewController(storeManager: StoreManagerKey.defaultValue)
        let careViewController = UINavigationController(rootViewController: view)
        careViewController.navigationBar.backgroundColor = UIColor { $0.userInterfaceStyle == .light ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1): #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) }

        return careViewController
    }

    @MainActor
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

struct CareView_Previews: PreviewProvider {
    static var previews: some View {
        CareView()
    }
}
