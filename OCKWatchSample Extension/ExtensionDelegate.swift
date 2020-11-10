//
//  ExtensionDelegate.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Apple. All rights reserved.
//
import CareKit
import CareKitStore
import ParseCareKit
import ParseSwift
import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    private let syncWithCloud = true //True to sync with ParseServer, False to Sync with iOS Phone
    private lazy var phone = OCKWatchConnectivityPeer()
    private var store: OCKStore!
    private var parse: ParseRemoteSynchronizationManager!
    private var sessionDelegate:SessionDelegate!
    private(set) var storeManager: OCKSynchronizedStoreManager!
    
    func applicationDidFinishLaunching() {
        
        //Parse-server setup
        ParseCareKitUtility.setupServer()

        //Clear items out of the Keychain on app first run. Used for debugging
        if UserDefaults.standard.object(forKey: "firstRun") == nil {
            try? User.logout()
            //This is no longer the first run
            UserDefaults.standard.setValue("firstRun", forKey: "firstRun")
            UserDefaults.standard.synchronize()
        }

        //Set default ACL for all Parse Classes
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        do {
            _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
        } catch {
            print(error.localizedDescription)
        }

        self.setupRemotes()
        
        //If the user isn't logged in, log them in
        if User.current == nil {
            
            var newUser = User()
            newUser.username = "ParseCareKit"
            newUser.password = "ThisIsAStrongPass1!"
            
            User.login(username: newUser.username!, password: newUser.password!) { result in
                    
                switch result {
                
                case .success(let user):
                    print("Parse login successful \(user)")
                    self.store.synchronize { error in
                        print(error?.localizedDescription ?? "Successful sync with Cloud!")
                    }
                case .failure(let error):
                    print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                    print("Parse error: \(String(describing: error))")
                }
            }
        } else {
            print("User is already signed in...")
            store.synchronize{ error in
                print(error?.localizedDescription ?? "Successful sync with Cloud!")
            }
        }
        
    }

    func setupRemotes() {
        do {
            if syncWithCloud{
                parse = try ParseRemoteSynchronizationManager(uuid: UUID(uuidString: "3B5FD9DA-C278-4582-90DC-101C08E7FC98")!, auto: true)
                store = OCKStore(name: "WatchParseStore", remote: parse)
                storeManager = OCKSynchronizedStoreManager(wrapping: store)
                
                parse?.parseRemoteDelegate = self
                sessionDelegate = CloudSyncSessionDelegate(store: store)
            }else {
                store = OCKStore(name: "PhoneStore", remote: phone)
                storeManager = OCKSynchronizedStoreManager(wrapping: store)

                phone.delegate = self
                sessionDelegate = LocalSyncSessionDelegate(remote: phone, store: store)
            }
            
            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()

        } catch {
            print("Error setting up remote: \(error.localizedDescription)")
        }
        
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}

extension ExtensionDelegate: OCKRemoteSynchronizationDelegate, ParseRemoteSynchronizationDelegate{
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        print("Implement... You need to have your push notifications certs setup to use this.")
    }
    
    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {
        print("Implement")
    }
    
    func successfullyPushedDataToCloud(){
        DispatchQueue.main.async {
            WCSession.default.sendMessage(["needToSyncNotification": "needToSyncNotification"], replyHandler: nil){
                error in
                print(error.localizedDescription)
            }
        }
    }
    
    func chooseConflictResolutionPolicy(_ conflict: OCKMergeConflictDescription, completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {
        let conflictPolicy = OCKMergeConflictResolutionPolicy.keepRemote
        completion(conflictPolicy)
    }
    
    func storeUpdatedOutcome(_ outcome: OCKOutcome) {
        storeManager.store.updateAnyOutcome(outcome, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedCarePlan(_ carePlan: OCKCarePlan) {
        storeManager.store.updateAnyCarePlan(carePlan, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedContact(_ contact: OCKContact) {
        storeManager.store.updateAnyContact(contact, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedPatient(_ patient: OCKPatient) {
        storeManager.store.updateAnyPatient(patient, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedTask(_ task: OCKTask) {
        storeManager.store.updateAnyTask(task, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    
}

protocol SessionDelegate: WCSessionDelegate {}

private class CloudSyncSessionDelegate: NSObject, SessionDelegate {
    let store: OCKStore
    
    init(store: OCKStore) {
        self.store = store
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("New session state: \(activationState)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        store.synchronize{ error in
            print(error?.localizedDescription ?? "Successful sync with Cloud!")
        }
    }
}

private class LocalSyncSessionDelegate: NSObject, SessionDelegate{
    let remote: OCKWatchConnectivityPeer
    let store: OCKStore
    
    init(remote: OCKWatchConnectivityPeer, store: OCKStore) {
        self.remote = remote
        self.store = store
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("New session state: \(activationState)")
        
        if activationState == .activated {
            store.synchronize{ error in
                print(error?.localizedDescription ?? "Successful sync with iPhone!")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print("Received message from iPhone")
        remote.reply(to: message, store: store){ reply in
            replyHandler(reply)
        }
    }
}
