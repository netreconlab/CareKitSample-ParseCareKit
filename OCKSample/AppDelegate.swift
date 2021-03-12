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
    
    let syncWithCloud = true //True to sync with ParseServer, False to Sync with iOS Watch
    var firstLogin = false
    var coreDataStore: OCKStore!
    var healthKitStore: OCKHealthKitPassthroughStore!
    var parse: ParseRemoteSynchronizationManager!
    private let watch = OCKWatchConnectivityPeer()
    private var sessionDelegate:SessionDelegate!
    private(set) var synchronizedStoreManager: OCKSynchronizedStoreManager?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Parse-server setup
        ParseCareKitUtility.setupServer()
        
        //Clear items out of the Keychain on app first run. Used for debugging
        if UserDefaults.standard.object(forKey: "firstRun") == nil {
            try? User.logout()
            //This is no longer the first run
            UserDefaults.standard.setValue(String("firstRun"), forKey: "firstRun")
            UserDefaults.standard.synchronize()
        }
        
        //Set default ACL for all ParseObjects
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false
        do {
            _ = try ParseACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
        } catch {
            print(error.localizedDescription)
        }

        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DispatchQueue.main.async {
            guard var currentInstallation = Installation.current else {
                return
            }
            currentInstallation.setDeviceToken(deviceToken)
            currentInstallation.channels = ["global"]
            currentInstallation.save { _ in }
        }
    }

    func setupRemotes(uuid: UUID? = nil) {
        do {
            
            if syncWithCloud {
                guard let uuid = uuid else {
                    print("Error in setupRemotes, uuid is nil")
                    return
                }
                parse = try ParseRemoteSynchronizationManager(uuid: uuid, auto: false, subscribeToServerUpdates: true)
                coreDataStore = OCKStore(name: "ParseStore", type: .onDisk(), remote: parse)
                parse?.parseRemoteDelegate = self
                sessionDelegate = CloudSyncSessionDelegate(store: coreDataStore)
            }else{
                coreDataStore = OCKStore(name: "WatchStore", type: .onDisk(), remote: watch)
                watch.delegate = self
                sessionDelegate = LocalSyncSessionDelegate(remote: watch, store: coreDataStore)
            }
            
            WCSession.default.delegate = sessionDelegate
            WCSession.default.activate()
            
            healthKitStore = OCKHealthKitPassthroughStore(store: coreDataStore)
            let coordinator = OCKStoreCoordinator()
            coordinator.attach(store: coreDataStore)
            coordinator.attach(eventStore: healthKitStore)
            synchronizedStoreManager = OCKSynchronizedStoreManager(wrapping: coordinator)
        } catch {
            print("Error setting up remote: \(error.localizedDescription)")
        }
    }
}

extension OCKStore {

    func addTasksIfNotPresent(_ tasks: [OCKTask]) {
        let tasksToAdd = tasks
        let taskIdsToAdd = tasksToAdd.compactMap { $0.id }

        //Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        fetchTasks(query: query) { result in
            
            if case let .success(foundTasks) = result {
                
                var tasksNotInStore = [OCKTask]()
                
                //Check results to see if there's a missing task
                tasksToAdd.forEach { potentialTask in
                    if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                        tasksNotInStore.append(potentialTask)
                    }
                }
                
                //Only add if there's a new task
                if tasksNotInStore.count > 0 {
                    self.addTasks(tasksNotInStore) { result in
                        switch result {
                        case .success: print("Added tasks into OCKStore!")
                        case .failure(let error): print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }

    func addContactsIfNotPresent(_ contacts: [OCKContact]) {
        let contactsToAdd = contacts
        let taskIdsToAdd = contactsToAdd.compactMap { $0.id }

        //Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = taskIdsToAdd

        fetchContacts(query: query) { result in
            
            if case let .success(foundContacts) = result {
                
                var contactsNotInStore = [OCKContact]()
                
                //Check results to see if there's a missing task
                contactsToAdd.forEach { potential in
                    if foundContacts.first(where: { $0.id == potential.id }) == nil {
                        contactsNotInStore.append(potential)
                    }
                }
                
                //Only add if there's a new task
                if contactsNotInStore.count > 0 {
                    self.addContacts(contactsNotInStore) { result in
                        switch result {
                        case .success: print("Added contacts into OCKStore!")
                        case .failure(let error): print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }

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

        addTasksIfNotPresent([nausea, doxylamine, kegels, stretch])
        
        
        var contact1 = OCKContact(id: "jane", givenName: "Jane",
                                  familyName: "Daniels", carePlanUUID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@uky.edu")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-2000")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 357-2040")]

        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2195 Harrodsburg Rd"
            address.city = "Lexington"
            address.state = "KY"
            address.postalCode = "40504"
            return address
        }()

        var contact2 = OCKContact(id: "matthew", givenName: "Matthew",
                                  familyName: "Reiff", carePlanUUID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-1000")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(859) 257-1234")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "1000 S Limestone"
            address.city = "Lexington"
            address.state = "KY"
            address.postalCode = "40536"
            return address
        }()

        addContactsIfNotPresent([contact1, contact2])
    }
}

extension OCKHealthKitPassthroughStore {

    func addTasksIfNotPresent(_ tasks: [OCKHealthKitTask]) {
        let tasksToAdd = tasks
        let taskIdsToAdd = tasksToAdd.compactMap { $0.id }

        //Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        fetchTasks(query: query) { result in
            
            if case let .success(foundTasks) = result {
                
                var tasksNotInStore = [OCKHealthKitTask]()
                
                //Check results to see if there's a missing task
                tasksToAdd.forEach { potentialTask in
                    if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                        tasksNotInStore.append(potentialTask)
                    }
                }
                
                //Only add if there's a new task
                if tasksNotInStore.count > 0 {
                    self.addTasks(tasksNotInStore) { result in
                        switch result {
                        case .success: print("Added tasks into HealthKitPassthroughStore!")
                        case .failure(let error): print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }

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

        addTasksIfNotPresent([steps])
    }
}

extension AppDelegate: ParseRemoteSynchronizationDelegate {

    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        }
    }
    
    func successfullyPushedDataToCloud() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        }
    }
    
    func remote(_ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {
        DispatchQueue.main.async {
            let progressPercentage = Int(progress * 100.0)
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.progressUpdate), userInfo: [Constants.progressUpdate: progressPercentage]))
        }
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
    
    let store: OCKStore
    
    init(store: OCKStore) {
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
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        if let _ = message[Constants.parseUserSessionTokenKey] as? String {
            print("Received message from Apple Watch requesting ParseUser, sending now")
            var returnMessage = [String: Any]()
            
            DispatchQueue.main.async {
                //Prepare data for watchOS
                guard let sessionToken = User.current?.sessionToken else {
                    return
                }
                
                returnMessage[Constants.parseUserSessionTokenKey] = sessionToken
                returnMessage[Constants.parseRemoteClockIDKey] = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey)
                replyHandler(returnMessage)
            }

        }
    }
}

private class LocalSyncSessionDelegate: NSObject, SessionDelegate {
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
            DispatchQueue.main.async {
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print("Received message from Apple Watch")
        remote.reply(to: message, store: store){ reply in
            replyHandler(reply)
        }
    }
}
