//
//  ContactSwiftUIView.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import SwiftUI
import UIKit
import CareKit
import CareKitStore

struct ContactSwiftUIView: UIViewControllerRepresentable {
    
    let manager: OCKSynchronizedStoreManager
    
    func makeUIViewController(context: Context) -> some UIViewController {
        
        let contacts = OCKContactsListViewController(storeManager: manager)
        return UINavigationController(rootViewController: contacts)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

struct ContactSwiftUIView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContactSwiftUIView(manager: OCKSynchronizedStoreManager(wrapping: OCKStore(name: "test")))
    }
}
