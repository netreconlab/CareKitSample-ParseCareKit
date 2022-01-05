//
//  OCKStore+Default.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import Contacts
import os.log
import UIKit
import ParseSwift
import ParseCareKit

extension OCKStore {

    func addTasksIfNotPresent(_ tasks: [OCKTask]) {
        let tasksToAdd = tasks
        let taskIdsToAdd = tasksToAdd.compactMap { $0.id }

        // Prepare query to see if tasks are already added
        var query = OCKTaskQuery(for: Date())
        query.ids = taskIdsToAdd

        fetchTasks(query: query) { result in

            if case let .success(foundTasks) = result {

                var tasksNotInStore = [OCKTask]()

                // Check results to see if there's a missing task
                tasksToAdd.forEach { potentialTask in
                    if foundTasks.first(where: { $0.id == potentialTask.id }) == nil {
                        tasksNotInStore.append(potentialTask)
                    }
                }

                // Only add if there's a new task
                if tasksNotInStore.count > 0 {
                    self.addTasks(tasksNotInStore) { result in
                        switch result {
                        case .success: Logger.appDelegate.info("Added tasks into OCKStore!")
                        case .failure(let error): Logger.appDelegate.error("\(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    func addContactsIfNotPresent(_ contacts: [OCKContact]) {
        let contactsToAdd = contacts
        let taskIdsToAdd = contactsToAdd.compactMap { $0.id }

        // Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = taskIdsToAdd

        fetchContacts(query: query) { result in

            if case let .success(foundContacts) = result {

                var contactsNotInStore = [OCKContact]()

                // Check results to see if there's a missing task
                contactsToAdd.forEach { potential in
                    if foundContacts.first(where: { $0.id == potential.id }) == nil {
                        contactsNotInStore.append(potential)
                    }
                }

                // Only add if there's a new task
                if contactsNotInStore.count > 0 {
                    self.addContacts(contactsNotInStore) { result in
                        switch result {
                        case .success: Logger.appDelegate.info("Added contacts into OCKStore!")
                        case .failure(let error): Logger.appDelegate.error("\(error.localizedDescription)")
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

        var doxylamine = OCKTask(id: TaskID.doxylamine, title: "Take Doxylamine",
                                 carePlanUUID: nil, schedule: schedule)
        doxylamine.instructions = "Take 25mg of doxylamine when you experience nausea."
        doxylamine.asset = "pills.fill"

        let nauseaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], duration: .allDay)
            ])

        var nausea = OCKTask(id: TaskID.nausea, title: "Track your nausea",
                             carePlanUUID: nil, schedule: nauseaSchedule)
        nausea.impactsAdherence = false
        nausea.instructions = "Tap the button below anytime you experience nausea."
        nausea.asset = "bed.double"

        let kegelElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 2))
        let kegelSchedule = OCKSchedule(composing: [kegelElement])
        var kegels = OCKTask(id: TaskID.kegels, title: "Kegel Exercises", carePlanUUID: nil, schedule: kegelSchedule)
        kegels.impactsAdherence = true
        kegels.instructions = "Perform kegel exercies"

        let stretchElement = OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1))
        let stretchSchedule = OCKSchedule(composing: [stretchElement])
        var stretch = OCKTask(id: "stretch", title: "Stretch", carePlanUUID: nil, schedule: stretchSchedule)
        stretch.impactsAdherence = true
        stretch.asset = "figure.walk"

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
