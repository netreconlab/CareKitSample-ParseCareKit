//
//  Profile.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKit
import CareKitStore
import SwiftUI
import ParseCareKit
import UIKit
import os.log

class ProfileViewModel: ObservableObject {
    
    @Published var patient: OCKPatient? = nil
    @Published var isLoggedOut = false
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate //Importing UIKit gives us access here to get the OCKStore and ParseRemote
    
    init() {
        Task {
            // Find this patient
            self.patient = await findCurrentProfile()
        }
    }
    
    @MainActor
    private func findCurrentProfile() async -> OCKPatient? {

        guard let uuid = getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            return nil
        }

        // Build query to search for OCKPatient
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) // This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] // Search for the current logged in user

        do {
            let foundPatient = try await self.appDelegate.synchronizedStoreManager?.store.fetchAnyPatients(query: queryForCurrentPatient)
            guard let currentPatient = foundPatient?.first as? OCKPatient else {
                return nil
            }
            return currentPatient
        } catch {
            Logger.profile.error("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error.localizedDescription)")
            return nil
        }
    }
    
    //Mark: User intentions
    
    func saveProfile(_ first: String, last: String, birth: Date) async throws {
        
        if var patientToUpdate = patient {
            // If there is a currentPatient that was fetched, check to see if any of the fields changed

            var patientHasBeenUpdated = false

            if patient?.name.givenName != first {
                patientHasBeenUpdated = true
                patientToUpdate.name.givenName = first
            }

            if patient?.name.familyName != last {
                patientHasBeenUpdated = true
                patientToUpdate.name.familyName = last
            }

            if patient?.birthday != birth {
                patientHasBeenUpdated = true
                patientToUpdate.birthday = birth
            }

            if patientHasBeenUpdated {
                let updated = try await appDelegate.synchronizedStoreManager?.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
                guard let updatedPatient = updated as? OCKPatient else {
                    return
                }
                self.patient = updatedPatient
            }

        } else {

            guard let remoteUUID = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
                Logger.profile.error("Error: The user currently isn't logged in")
                isLoggedOut = true
                return
            }

            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth

            // This is new patient that has never been saved before
            let new = try await appDelegate.synchronizedStoreManager?.store.addAnyPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
            guard let newPatient = new as? OCKPatient else {
                return
            }
            self.patient = newPatient
        }
    }
    
    @MainActor
    func savePatientAfterSignUp(_ first: String, last: String) async throws -> OCKPatient {

        let remoteUUID = UUID()

        // Because of the app delegate access above, we can place the initial data in the database
        self.appDelegate.setupRemotes(uuid: remoteUUID)
        self.appDelegate.coreDataStore.populateSampleData()
        self.appDelegate.healthKitStore.populateSampleData()
        self.appDelegate.parse.automaticallySynchronizes = true
        self.appDelegate.firstLogin = true

        // Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))

        // Save remote ID to local
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        var newPatient = OCKPatient(id: remoteUUID.uuidString, givenName: first, familyName: last)
        newPatient.userInfo = [Constants.parseRemoteClockIDKey: remoteUUID.uuidString] // Save the remoteId String

        let savedPatient = try await appDelegate.synchronizedStoreManager?.store.addAnyPatient(newPatient)
        guard let patient = savedPatient as? OCKPatient else {
            throw AppError.couldntCast
        }
        self.patient = patient

        Logger.profile.info("Successfully added a new Patient")
        return patient
    }
    
    func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
            return nil
        }
        
        return UUID(uuidString: uuid)
    }
    
    func getRemoteClockUUIDAfterLoginFromCloud() async throws -> UUID {

        let query = PCKPatient.query()
        let patient = try await query.first()
        guard let uuid = patient.userInfo?[Constants.parseRemoteClockIDKey],
              let remoteClockId = UUID(uuidString: uuid) else {
            throw AppError.valueNotFoundInUserInfo
        }
        return remoteClockId
    }
    
    @MainActor
    func setupRemoteAfterLoginButtonTapped() async throws -> UUID {

        let uuid = try await getRemoteClockUUIDAfterLoginFromCloud()

        self.appDelegate.setupRemotes(uuid: uuid)
        self.appDelegate.parse.automaticallySynchronizes = true
        self.appDelegate.firstLogin = true

        // Save remote ID to local
        UserDefaults.standard.setValue(uuid.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        return uuid
    }
    
    //You may not have seen "throws" before, but it's simple, this throws an error if one occurs, if not it behaves as normal
    //Normally, you've seen do {} catch{} which catches the error, same concept...
    func logout() throws {
        try User.logout()
        isLoggedOut = true
        UserDefaults.standard.removeObject(forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        try appDelegate.healthKitStore.reset()
        try appDelegate.coreDataStore.delete() // Delete data in local OCKStore database
    }
}
