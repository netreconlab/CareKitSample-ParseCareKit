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
import Combine

@MainActor
class ProfileViewModel: ObservableObject {

    @Published var patient: OCKPatient?
    @Published var isLoggedOut = false {
        willSet {
            if newValue {
                error = nil
                patient = nil
                clearSubscriptions()
            }
        }
    }
    @Published public internal(set) var error: Error?
    private(set) var storeManager: OCKSynchronizedStoreManager?
    private var cancellables: Set<AnyCancellable> = []

    init() {
        reloadViewModel()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewModel),
                                               name: Notification.Name(rawValue: Constants.reloadView),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(replaceStore),
                                               name: Notification.Name(rawValue: Constants.storeInitialized),
                                               object: nil)
    }

    // MARK: Helpers

    @objc private func reloadViewModel() {
        Task {
            _ = await findAndObserveCurrentProfile()
        }
    }

    @objc private func replaceStore() {
        guard let currentStore = StoreManagerKey.defaultValue else { return }
        storeManager = currentStore
        reloadViewModel()
    }

    func refreshViewIfNeeded() {
        if cancellables.count == 0 {
            reloadViewModel()
        }
    }

    private func findAndObserveCurrentProfile() async {

        guard let uuid = getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            return
        }

        clearSubscriptions()

        // Build query to search for OCKPatient
        // swiftlint:disable:next line_length
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) // This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] // Search for the current logged in user

        do {
            let foundPatient = try await self.storeManager?.store.fetchAnyPatients(query: queryForCurrentPatient)
            guard let currentPatient = foundPatient?.first as? OCKPatient else {
                // swiftlint:disable:next line_length
                Logger.profile.error("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved.")
                return
            }
            self.observePatient(currentPatient)
        } catch {
            // swiftlint:disable:next line_length
            Logger.profile.error("Error: Couldn't find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error.localizedDescription)")
        }
    }

    private func observePatient(_ patient: OCKPatient) {

        storeManager?.publisher(forPatient: patient, categories: [.add, .update, .delete])
            .sink { [weak self] in
                self?.patient = $0 as? OCKPatient
            }
            .store(in: &cancellables)
    }

    private func clearSubscriptions() {
        cancellables = []
    }

    func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
            return nil
        }

        return UUID(uuidString: uuid)
    }

    static func getRemoteClockUUIDAfterLoginFromCloud() async throws -> UUID {

        let query = PCKPatient.query()
        let patient = try await query.first()
        guard let uuid = patient.userInfo?[Constants.parseRemoteClockIDKey],
              let remoteClockId = UUID(uuidString: uuid) else {
            throw AppError.valueNotFoundInUserInfo
        }
        return remoteClockId
    }

    static func setupRemoteAfterLoginButtonTapped() async throws {

        let remoteUUID = try await Self.getRemoteClockUUIDAfterLoginFromCloud()

        // Save remote ID to local
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            try LoginViewModel.setDefaultACL()
        } catch {
            Logger.profile.error("Couldn't set defaultACL: \(error.localizedDescription)")
        }

        // Importing UIKit gives us access here to get the OCKStore and ParseRemote
        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setupRemotes(uuid: remoteUUID)
        appDelegate.parse.automaticallySynchronizes = true

        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        return
    }

    // MARK: User intentions

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
                let updated = try await storeManager?.store.updateAnyPatient(patientToUpdate)
                Logger.profile.info("Successfully updated patient")
                guard let updatedPatient = updated as? OCKPatient else {
                    return
                }
                self.patient = updatedPatient
            }

        } else {
            // swiftlint:disable:next line_length
            guard let remoteUUID = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
                Logger.profile.error("Error: The user currently isn't logged in")
                isLoggedOut = true
                return
            }

            var newPatient = OCKPatient(id: remoteUUID, givenName: first, familyName: last)
            newPatient.birthday = birth

            // This is new patient that has never been saved before
            let new = try await storeManager?.store.addAnyPatient(newPatient)
            Logger.profile.info("Succesffully saved new patient")
            guard let newPatient = new as? OCKPatient else {
                return
            }
            self.patient = newPatient
        }
    }

    static func savePatientAfterSignUp(_ first: String, last: String) async throws -> OCKPatient {

        let remoteUUID = UUID()

        // Save remote ID locally
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            try LoginViewModel.setDefaultACL()
        } catch {
            Logger.profile.error("Couldn't set defaultACL: \(error.localizedDescription)")
        }

        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setupRemotes(uuid: remoteUUID)

        guard let storeManager = appDelegate.storeManager else {
            throw AppError.couldntBeUnwrapped
        }

        let newPatient = OCKPatient(remoteUUID: remoteUUID,
                                    id: remoteUUID.uuidString,
                                    givenName: first,
                                    familyName: last)

        let savedPatient = try await storeManager.store.addAnyPatient(newPatient)
        guard let patient = savedPatient as? OCKPatient else {
            throw AppError.couldntCast
        }

        try await appDelegate.coreDataStore.populateSampleData()
        try await appDelegate.healthKitStore.populateSampleData()
        appDelegate.parse.automaticallySynchronizes = true

        // Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        Logger.profile.info("Successfully added a new Patient")
        return patient
    }

    // You may not have seen "throws" before, but it's simple,
    // this throws an error if one occurs, if not it behaves as normal
    // Normally, you've seen do {} catch{} which catches the error, same concept...
    func logout() async {
        do {
            try await User.logout()
        } catch {
            Logger.profile.error("Error logging out: \(error.localizedDescription)")
        }
        UserDefaults.standard.removeObject(forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        // swiftlint:disable:next force_cast
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.resetAppToInitialState()
        isLoggedOut = true
    }
}
