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

    func makeUIViewController(context: Context) -> some UIViewController {
        let contactsView = OCKContactsListViewController(storeManager: StoreManagerKey.defaultValue)
        return UINavigationController(rootViewController: contactsView)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView()
    }
}
