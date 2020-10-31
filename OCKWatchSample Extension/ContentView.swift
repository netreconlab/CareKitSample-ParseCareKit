//
//  ContentView.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import CareKit
import CareKitStore
import SwiftUI

private struct StoreManagerKey: EnvironmentKey {
    
    static var defaultValue: OCKSynchronizedStoreManager {
        let extensionDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        return extensionDelegate.storeManager
    }
}

extension EnvironmentValues {
    
    var storeManager: OCKSynchronizedStoreManager {
        get {
            self[StoreManagerKey.self]
        }
        
        set{
            self[StoreManagerKey.self] = newValue
        }
    }
}

struct ContentView: View {
    
    @Environment(\.storeManager) private var storeManager
    
    var body: some View {
        
        ScrollView {
            
            InstructionsTaskView(taskID: "stretch", eventQuery: OCKEventQuery(for: Date()), storeManager: storeManager)
            
            SimpleTaskView(taskID: "kegels", eventQuery: OCKEventQuery(for: Date()), storeManager: storeManager){ controller in
                
                .init(title: Text(controller.viewModel?.title ?? ""), detail: nil, isComplete: controller.viewModel?.isComplete ?? false, action: controller.viewModel?.action ?? {})
            }
            
        }.accentColor(Color(#colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1)))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
