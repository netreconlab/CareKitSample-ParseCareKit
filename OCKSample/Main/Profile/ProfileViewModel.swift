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

class ProfileViewModel: ObservableObject {

    @Published var patient: OCKPatient?
    @Published public internal(set) var error: Error?
    private(set) var storeManager: OCKSynchronizedStoreManager?
    private var cancellables: Set<AnyCancellable> = []

    init() {
        storeManager = StoreManagerKey.defaultValue
        reloadViewModel()
    }

    // MARK: Helpers

    private func reloadViewModel() {
        Task {
            _ = await findAndObserveCurrentProfile()
        }
    }

    @MainActor
    @objc private func replaceStore() {
        let updatedStoreManager = StoreManagerKey.defaultValue
        guard storeManager !== updatedStoreManager else {
            return
        }
        storeManager = updatedStoreManager
        reloadViewModel()
    }

    func refreshViewIfNeeded() {
        if cancellables.count == 0 {
            reloadViewModel()
        }
    }

    @MainActor
    private func findAndObserveCurrentProfile() async {

        guard let uuid = Self.getRemoteClockUUIDAfterLoginFromLocalStorage() else {
            return
        }

        clearSubscriptions()

        // Build query to search for OCKPatient
        // swiftlint:disable:next line_length
        var queryForCurrentPatient = OCKPatientQuery(for: Date()) // This makes the query for the current version of Patient
        queryForCurrentPatient.ids = [uuid.uuidString] // Search for the current logged in user

        do {
            guard let appDelegate = AppDelegateKey.defaultValue,
                  let foundPatient = try await appDelegate.store?.fetchPatients(query: queryForCurrentPatient),
                let currentPatient = foundPatient.first else {
                // swiftlint:disable:next line_length
                Logger.profile.error("Error: Could not find patient with id \"\(uuid)\". It's possible they have never been saved.")
                return
            }
            self.observePatient(currentPatient)
        } catch {
            // swiftlint:disable:next line_length
            Logger.profile.error("Error: Could not find patient with id \"\(uuid)\". It's possible they have never been saved. Query error: \(error.localizedDescription)")
        }
    }

    @MainActor
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

    static func getRemoteClockUUIDAfterLoginFromLocalStorage() -> UUID? {
        guard let uuid = UserDefaults.standard.object(forKey: Constants.parseRemoteClockIDKey) as? String else {
            return nil
        }

        return UUID(uuidString: uuid)
    }

    static func getRemoteClockUUIDAfterLoginFromCloud() async throws -> UUID {

        guard let lastUserTypeSelected = User.current?.lastTypeSelected,
              let remoteClockUUID = User.current?.userTypeUUIDs?[lastUserTypeSelected] else {
                  throw AppError.remoteClockIDNotAvailable
              }
        return remoteClockUUID
    }

    @MainActor
    static func setupRemoteAfterLoginButtonTapped() async throws {

        let remoteUUID = try await Self.getRemoteClockUUIDAfterLoginFromCloud()

        // Save remote ID to local
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            try LoginViewModel.setDefaultACL()
        } catch {
            Logger.profile.error("Could not set defaultACL: \(error.localizedDescription)")
        }

        // Importing UIKit gives us access here to get the OCKStore and ParseRemote
        guard let appDelegate = AppDelegateKey.defaultValue else {
            return
        }
        appDelegate.setupRemotes(uuid: remoteUUID)
        appDelegate.parseRemote.automaticallySynchronizes = true

        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        return
    }

    // MARK: User intentions
    @MainActor
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
                Logger.profile.error("Error: The user currently is not logged in")
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

    @MainActor
    static func savePatientAfterSignUp(_ type: UserType, first: String, last: String) async throws -> OCKPatient {

        let remoteUUID = UUID()

        // Save remote ID locally
        UserDefaults.standard.setValue(remoteUUID.uuidString, forKey: Constants.parseRemoteClockIDKey)
        UserDefaults.standard.synchronize()

        do {
            try LoginViewModel.setDefaultACL()
        } catch {
            Logger.profile.error("Could not set defaultACL: \(error.localizedDescription)")
        }

        guard let appDelegate = AppDelegateKey.defaultValue else {
            throw AppError.couldntBeUnwrapped
        }
        appDelegate.setupRemotes(uuid: remoteUUID)
        let storeManager = appDelegate.storeManager

        var newPatient = OCKPatient(remoteUUID: remoteUUID,
                                    id: remoteUUID.uuidString,
                                    givenName: first,
                                    familyName: last)
        newPatient.userType = type
        let savedPatient = try await storeManager.store.addAnyPatient(newPatient)
        guard let patient = savedPatient as? OCKPatient else {
            throw AppError.couldntCast
        }

        try await appDelegate.store?.populateSampleData()
        try await appDelegate.healthKitStore.populateSampleData()
        if isSyncingWithCloud {
            appDelegate.parseRemote.automaticallySynchronizes = true
        }

        // Post notification to sync
        NotificationCenter.default.post(.init(name: Notification.Name(rawValue: Constants.requestSync)))
        Logger.profile.info("Successfully added a new Patient")
        return patient
    }
}
