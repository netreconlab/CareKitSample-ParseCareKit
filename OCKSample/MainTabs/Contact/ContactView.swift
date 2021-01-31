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

struct ContactView: UIViewControllerRepresentable {
    
    let manager: OCKSynchronizedStoreManager
    
    func makeUIViewController(context: Context) -> some UIViewController {
        
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
