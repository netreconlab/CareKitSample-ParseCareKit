/*
Copyright (c) 2019, Apple Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit
import CareKitStore
import Contacts
import UIKit
import HealthKit
import ParseCareKit
import ParseSwift
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let syncWithCloud = true //True to sync with ParseServer, False to Sync with iOS Watch
    var coreDataStore: OCKStore!
    let healthKitStore = OCKHealthKitPassthroughStore(name: "SampleAppHealthKitPassthroughStore", type: .inMemory)
    private lazy var parse = try? ParseRemoteSynchronizationManager(uuid: UUID(uuidString: "3B5FD9DA-C278-4582-90DC-101C08E7FC98")!, auto: false)
    private lazy var watch = OCKWatchConnectivityPeer()
    private var sessionDelegate:SessionDelegate!
    private(set) var synchronizedStoreManager: OCKSynchronizedStoreManager!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        ParseCareKitUtility.setupServer()
        //Clear items out of the Keychain on app first run. Used for debugging
        //try? User.logout()
        
        if syncWithCloud{
            coreDataStore = OCKStore(name: "SampleAppStore", type: .onDisk, remote: parse)
            parse?.parseRemoteDelegate = self
            sessionDelegate = CloudSyncSessionDelegate(store: coreDataStore)
        }else{
            coreDataStore = OCKStore(name: "SampleAppStore", type: .onDisk, remote: watch)
            sessionDelegate = LocalSyncSessionDelegate(remote: watch, store: coreDataStore)
        }
        
        WCSession.default.delegate = sessionDelegate
        WCSession.default.activate()
        
        let coordinator = OCKStoreCoordinator()
        coordinator.attach(eventStore: healthKitStore)
        coordinator.attach(store: coreDataStore)

        synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        
        self.coreDataStore.populateSampleData()
        self.healthKitStore.populateSampleData()
        
        //Set default ACL for all Parse Classes
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        do {
            _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
        } catch {
            print(error.localizedDescription)
        }
        
        //If the user isn't logged in, log them in
        guard let _ = User.current else{
            
            var newUser = User()
            newUser.username = "ParseCareKit2"
            newUser.password = "ThisIsAStrongPass1!"
            
            newUser.signup { result in
                switch result {
                
                case .success(let user):
                    print("Parse signup successful \(user)")
                    self.parse?.automaticallySynchronizes = true
                    self.coreDataStore.synchronize{error in
                        print(error?.localizedDescription ?? "Successful first sync!")
                    }
                case .failure(let parseError):
                    switch parseError.code{
                    case .usernameTaken: //Account already exists for this username.
                        User.login(username: newUser.username!, password: newUser.password!){ result in
                                
                            switch result {
                            
                            case .success(let user):
                                print("Parse login successful \(user)")
                                self.parse?.automaticallySynchronizes = true
                                self.coreDataStore.synchronize{error in
                                    print(error?.localizedDescription ?? "Successful first sync!")
                                }
                            case .failure(let error):
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
                                self.coreDataStore.synchronize{error in
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
                }
            }
                
            return true
        }
        
        self.parse?.automaticallySynchronizes = true
        print("User is already signed in. Autosync is set to \(String(describing: self.parse?.automaticallySynchronizes))")
        self.coreDataStore.synchronize{error in
            print(error?.localizedDescription ?? "Completed sync after app startup!")
        }

        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

private extension OCKStore {

    // Adds tasks and contacts into the store
    func populateSampleData() {

        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!

        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1)),

            OCKScheduleElement(start: afterLunch, end: nil,
                               interval: DateComponents(day: 2))
        ])

        var doxylamine = OCKTask(id: "doxylamine", title: "Take Doxylamine",
                                 carePlanUUID: nil, schedule: schedule)
        doxylamine.instructions = "Take 25mg of doxylamine when you experience nausea."

        let nauseaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], duration: .allDay)
            ])

        var nausea = OCKTask(id: "nausea", title: "Track your nausea",
                             carePlanUUID: nil, schedule: nauseaSchedule)
        nausea.impactsAdherence = false
        nausea.instructions = "Tap the button below anytime you experience nausea."

        let kegelElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 2))
        let kegelSchedule = OCKSchedule(composing: [kegelElement])
        var kegels = OCKTask(id: "kegels", title: "Kegel Exercises", carePlanUUID: nil, schedule: kegelSchedule)
        kegels.impactsAdherence = true
        kegels.instructions = "Perform kegel exercies"
        
        let stretchElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1))
        let stretchSchedule = OCKSchedule(composing: [stretchElement])
        var stretch = OCKTask(id: "stretch", title: "Stretch", carePlanUUID: nil, schedule: stretchSchedule)
        stretch.impactsAdherence = true

        addTasks([nausea, doxylamine, kegels, stretch], callbackQueue: .main, completion: nil)

        var contact1 = OCKContact(id: "jane", givenName: "Jane",
                                  familyName: "Daniels", carePlanUUID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@icloud.com")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]

        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2598 Reposa Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()

        var contact2 = OCKContact(id: "matthew", givenName: "Matthew",
                                  familyName: "Reiff", carePlanUUID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "396 El Verano Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()

        addContacts([contact1, contact2])
    }
}

extension OCKHealthKitPassthroughStore {

    func populateSampleData() {

        let schedule = OCKSchedule.dailyAtTime(
            hour: 8, minutes: 0, start: Date(), end: nil, text: nil,
            duration: .hours(12), targetValues: [OCKOutcomeValue(2000.0, units: "Steps")])

        let steps = OCKHealthKitTask(
            id: "steps",
            title: "Steps",
            carePlanUUID: nil,
            schedule: schedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: .count()))

        addTasks([steps]) { result in
            switch result {
            case .success: print("Added tasks into HealthKitPassthroughStore!")
            case .failure(let error): print("Error: \(error)")
            }
        }
    }
}

extension AppDelegate: OCKRemoteSynchronizationDelegate, ParseRemoteSynchronizationDelegate{
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        print("Implement")
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
        let conflictPolicy = OCKMergeConflictResolutionPolicy.keepRemote
        completion(conflictPolicy)
    }
    
    func storeUpdatedOutcome(_ outcome: OCKOutcome) {
        synchronizedStoreManager.store.updateAnyOutcome(outcome, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedCarePlan(_ carePlan: OCKCarePlan) {
        synchronizedStoreManager.store.updateAnyCarePlan(carePlan, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedContact(_ contact: OCKContact) {
        synchronizedStoreManager.store.updateAnyContact(contact, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedPatient(_ patient: OCKPatient) {
        synchronizedStoreManager.store.updateAnyPatient(patient, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    func storeUpdatedTask(_ task: OCKTask) {
        synchronizedStoreManager.store.updateAnyTask(task, callbackQueue: .global(qos: .background), completion: nil)
    }
    
    
}

protocol SessionDelegate: WCSessionDelegate {
    
}

private class CloudSyncSessionDelegate: NSObject, SessionDelegate{
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
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
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
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
