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

    let manager: OCKSynchronizedStoreManager?

    func makeUIViewController(context: Context) -> some UIViewController {
        guard let manager = StoreManagerKey.defaultValue else {
            Logger.contact.error("Couldn't unwrap storeManager")
            return UINavigationController()
        }
        let contacts = OCKContactsListViewController(storeManager: manager)
        return UINavigationController(rootViewController: contacts)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

struct ContactView_Previews: PreviewProvider {

    static var previews: some View {
        ContactView(manager: OCKSynchronizedStoreManager(wrapping: OCKStore(name: "test")))
    }
}
