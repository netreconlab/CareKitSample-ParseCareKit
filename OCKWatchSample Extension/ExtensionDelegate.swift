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
import Parse
import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    private let syncWithCloud = true //True to sync with ParseServer, False to Sync with iOS Phone
    private lazy var phone = OCKWatchConnectivityPeer()
    private var store: OCKStore!
    private lazy var parse = ParseRemoteSynchronizationManager(uuid: UUID(uuidString: "3B5FD9DA-C278-4582-90DC-101C08E7FC98")!, auto: true)
    private var sessionDelegate:SessionDelegate!
    private(set) lazy var storeManager = OCKSynchronizedStoreManager(wrapping: store)
    
    func applicationDidFinishLaunching() {
        
        ParseCareKitUtility.setupServer()
        
        if syncWithCloud{
            store = OCKStore(name: "SampleWatchAppStore", remote: parse)
            parse.parseRemoteDelegate = self
            sessionDelegate = CloudSyncSessionDelegate(store: store)
        }else {
            store = OCKStore(name: "SampleWatchAppStore", remote: phone)
            sessionDelegate =  LocalSyncSessionDelegate(remote: phone, store: store)
        }
        
        WCSession.default.delegate = sessionDelegate
        WCSession.default.activate()
        
        PFUser.enableRevocableSessionInBackground()
        
        //Set default ACL for all Parse Classes
        let defaultACL = PFACL()
        defaultACL.hasPublicReadAccess = false
        defaultACL.hasPublicWriteAccess = false
        PFACL.setDefault(defaultACL, withAccessForCurrentUser:true)
        
        //If the user isn't logged in, log them in
        guard let _ = PFUser.current() else{
            
            let newUser = PFUser()
            newUser.username = "ParseCareKit"
            newUser.password = "ThisIsAStrongPass1!"
            
            newUser.signUpInBackground(){
                (success,error) in
                if !success{
                    guard let parseError = error as NSError? else{
                        //There was a different issue that we don't know how to handle
                        print("Error signing in. Unkown...")
                        return
                    }
                    
                    switch parseError.code{
                    case 202: //Account already exists for this username.
                        PFUser.logInWithUsername(inBackground: newUser.username!, password: newUser.password!){
                            (user, error) -> Void in
                                
                            if user != nil{
                                print("Parse login successful \(user!)")
                                self.store.synchronize{error in
                                    print(error?.localizedDescription ?? "Successful sync!")
                                }
                            }else{
                                print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                                print("Parse error: \(String(describing: error))")
                            }
                        }
                        //How to login anonymously
                        /*
                        PFAnonymousUtils.logIn{
                            (user, error) -> Void in
                        
                            if user != nil{
                                print("Parse login successful \(user!)")
                                self.store.synchronize{error in
                                    print(error?.localizedDescription ?? "Successful sync!")
                                }
                            }else{
                                print("*** Error logging into Parse Server. Are you running parse-postgres and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                                print("Parse error: \(String(describing: error))")
                            }
                        }*/
                    default:
                        //There was a different issue that we don't know how to handle
                        print("*** Error Signing up as user for Parse Server. Are you running parse-postgres and is the initialization complete? Check http://localhost:1337 in your browser. If you are still having problems check for help here: https://github.com/netreconlab/parse-postgres#getting-started ***")
                        print(parseError)
                    }
                    return
                }else{
                    print("Parse signup successful \(PFUser.current()!)")
                    self.store.synchronize{error in
                        print(error?.localizedDescription ?? "Syncing for the first time!")
                    }
                }
            }
            return
        }
        
        print("User already signed up, attempting to sync...")
        self.store.synchronize{error in
            print(error?.localizedDescription ?? "Successful sync!")
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if PFUser.current() != nil{
            self.store.synchronize{error in
                print(error?.localizedDescription ?? "Successful sync!")
            }
        }
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
        WCSession.default.sendMessage(["needToSyncNotification": "needToSyncNotification"], replyHandler: nil){
            error in
            print(error.localizedDescription)
        }
    }
    
    func chooseConflictResolutionPolicy(_ conflict: OCKMergeConflictDescription, completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {
        let conflictPolicy = OCKMergeConflictResolutionPolicy.keepDevice
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

protocol SessionDelegate: WCSessionDelegate {
    
}

private class CloudSyncSessionDelegate: NSObject, SessionDelegate{
    let store: OCKStore
    
    init(store: OCKStore) {
        self.store = store
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("New session state: \(activationState)")
        
        if activationState == .activated {
            store.synchronize{ error in
                print(error?.localizedDescription ?? "Successful sync with Cloud!")
            }
        }
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
                print(error?.localizedDescription ?? "Successful sync!")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print("Received message from peer")
        
        remote.reply(to: message, store: store){ reply in
            print("Sending reply to peer!")
            
            replyHandler(reply)
        }
    }
}
