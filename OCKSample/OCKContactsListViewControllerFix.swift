//
//  OCKContactsListViewControllerFix.swift
//  OCKSample
//
//  Created by Corey Baker on 11/25/20.
//  Copyright © 2020 Apple. All rights reserved.
//

@testable import CareKit
import CareKitStore
import CareKitUI
import Combine
import Foundation

/// An `OCKListViewController` that automatically queries and displays contacts in the `Store` using
/// `OCKDetailedContactViewController`s.
open class OCKContactsListViewControllerFix: OCKListViewController {

    // MARK: Properties

    /// The manager of the `Store` from which the `Contact` data is fetched.
    public let storeManager: OCKSynchronizedStoreManager

    /// If set, the delegate will receive callbacks when important events happen at the list view controller level.
    public weak var delegate: OCKContactsListViewControllerDelegate?

    /// If set, the delegate will receive callbacks when important events happen inside the contact view controllers.
    public weak var contactDelegate: OCKContactViewControllerDelegate?

    private var subscription: Cancellable?

    // MARK: - Life Cycle

    /// Initialize using a store manager. All of the contacts in the store manager will be queried and dispalyed.
    ///
    /// - Parameters:
    ///   - storeManager: The store manager owning the store whose contacts should be displayed.
    public init(storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        title = loc("CONTACTS")
        subscribe()
        fetchContacts()
    }

    // MARK: - Methods

    private func subscribe() {
        subscription?.cancel()
        subscription = storeManager.contactsPublisher(categories: [.add, .update]).sink { _ in
            self.fetchContacts()
        }
    }

    /// `fetchContacts` asynchronously retrieves an array of contacts stored in a `Result`
    /// and makes corresponding `OCKDetailedContactViewController`s.
    private func fetchContacts() {
        storeManager.store.fetchAnyContacts(query: OCKContactQuery(for: Date()), callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                if self.delegate == nil {
                    log(.error, "A contacts error occurred, but no delegate was set to forward it to!", error: error)
                }
                
                if let casted = self as? OCKContactsListViewController {
                    self.delegate?.contactsListViewController(casted, didEncounterError: error)
                }
            case .success(let contacts):
                self.clear()
                for contact in contacts {
                    let contactViewController = OCKDetailedContactViewController(contact: contact, storeManager: self.storeManager)
                    contactViewController.delegate = self.contactDelegate
                    self.appendViewController(contactViewController, animated: false)
                }
            }
        }
    }
}
