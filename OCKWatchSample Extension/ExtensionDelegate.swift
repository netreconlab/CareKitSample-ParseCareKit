//
//  ExtensionDelegate.swift
//  OCKWatchSample Extension
//
//  Created by Corey Baker on 6/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//
import CareKit
import CareKitStore
import ParseCareKit
import ParseSwift
import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    let syncWithCloud = true //True to sync with ParseServer, False to Sync with iOS Phone
    private lazy var phone = OCKWatchConnectivityPeer()
    var store: OCKStore!
    private var parse: ParseRemoteSynchronizationManager!
    private var sessionDelegate:SessionDelegate!
    private(set) var storeManager: OCKSynchronizedStoreManager!
    
    func applicationDidFinishLaunching() {
        
        //Parse-server setup
        ParseCareKitUtility.setupServer()

        //Set default ACL for all ParseObjects
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        do {
            _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
        } catch {
            print(error.localizedDescription)
        }
        
        //Clear items out of the Keychain on app first run. Used for debugging
        if UserDefaults.standard.object(forKey: "firstRun") == nil {
            try? User.logout()
            //This is no longer the first run
            UserDefaults.standard.setValue("firstRun", forKey: "firstRun")
            UserDefaults.standard.synchronize()
        }
        
        //If the user isn't logged in, log them in
        if User.current != nil {
            self.setupRemotes(uuid: UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String) //Setup for getting info
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
            }
            print("User is already signed in...")
            store.synchronize{ error in
                print(error?.localizedDescription ?? "Successful sync with Cloud!")
            }
        } else {
            setupRemotes(uuid: nil) //Setup for getting info
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        DispatchQueue.main.async {
            guard var currentInstallation = Installation.current else {
                return
            }
            currentInstallation.setDeviceToken(deviceToken)
            currentInstallation.channels = ["global"]
            currentInstallation.save { _ in }
        }
    }

    func setupRemotes(uuid: String? = nil) {
        do {
            if syncWithCloud{
                guard let uuid = uuid,
                      let remotUUID = UUID(uuidString: uuid) else {
                    print("Couldn't get remote clock UUID from User defaults")
                    sessionDelegate = CloudSyncSessionDelegate(store: nil)
                    WCSession.default.delegate = sessionDelegate
                    WCSession.default.activate()
                    return
                }
                parse = try ParseRemoteSynchronizationManager(uuid: remotUUID, auto: true, subscribeToServerUpdates: true)
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

    func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: "remoteClockUUID") as? String else {
            return nil
        }
        
        return UUID(uuidString: uuid)
    }
}

extension ExtensionDelegate: ParseRemoteSynchronizationDelegate {
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        store?.synchronize{ error in
            print(error?.localizedDescription ?? "Successful sync with Cloud!")
        }
    }
    
    func successfullyPushedDataToCloud() {
        print("Finished pusshing data.")
    }
    
    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {
        print("Synchronization completed: \(progress)")
    }
    
    func chooseConflictResolution(conflicts: [OCKEntity], completion: @escaping OCKResultClosure<OCKEntity>) {
        if let first = conflicts.first {
            completion(.success(first))
        } else {
            completion(.failure(.remoteSynchronizationFailed(reason: "Error, non selected for conflict")))
        }
    }
}

protocol SessionDelegate: WCSessionDelegate {}

private class CloudSyncSessionDelegate: NSObject, SessionDelegate {
    var store: OCKStore?
    
    init(store: OCKStore?) {
        self.store = store
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("New session state: \(activationState)")
        
        switch activationState {
        case .activated:
            
            DispatchQueue.main.async {
                //If user isn't logged in, request login from iPhone
                if User.current == nil {
                    WCSession.default.sendMessage([Constants.parseUserSessionTokenKey: Constants.parseUserSessionTokenKey], replyHandler: { reply in
                        
                        guard let sessionToken = reply[Constants.parseUserSessionTokenKey] as? String,
                              let uuidString = reply[Constants.parseRemoteClockIDKey] as? String else {
                            print("Error: data missing in iPhone message")
                            return
                        }
                        
                        //Save remoteUUID for later
                        UserDefaults.standard.setValue(uuidString, forKey: Constants.parseRemoteClockIDKey)
                        UserDefaults.standard.synchronize()
                        
                        User().become(sessionToken: sessionToken) { result in
                                
                            switch result {
                            
                            case .success(let user):
                                print("Parse login successful \(user)")
                                let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
                                watchDelegate.setupRemotes(uuid: uuidString)
                                watchDelegate.store.synchronize { error in
                                    print(error?.localizedDescription ?? "Successful sync with Cloud!")
                                }
                                
                                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.userLoggedIn)))
                                
                            case .failure(let error):
                                print("*** Error logging into Parse Server. If you are still having problems check for help here: https://github.com/netreconlab/parse-hipaa#getting-started ***")
                                print("Parse error: \(String(describing: error))")
                            }
                        }
                    }) { error in
                        print(error)
                    }
                }
            }
        default:
            print("")
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
