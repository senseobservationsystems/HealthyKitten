//
//  FirstViewController.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 10/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import UIKit

class EventsViewController: UIViewController {

    @IBOutlet weak var hasContentView: UIView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var exportButton: UIBarButtonItem!
    
    var viewModel: EventsViewModel! {
        didSet {
            viewModel.addObserver { _ in
                DispatchQueue.main.async { [weak self] in
                    self?.updateUI()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100.0
        
        updateUI()
    }
    
    func updateUI() {
        emptyStateView?.isHidden = viewModel.emptyStateViewHidden
        hasContentView?.isHidden = viewModel.hasContentViewHidden
        clearButton?.isEnabled = viewModel.clearButtonEnabled
        exportButton?.isEnabled = viewModel.clearButtonEnabled
        tableView?.reloadData()
    }

    @IBAction func clearList(_ sender: UIBarButtonItem) {
        viewModel.deleteAllData()
    }
    
    @IBAction func exportList(_ sender: UIBarButtonItem) {
        let eventsString = [viewModel.events.debugDescription]
        let activityVC = UIActivityViewController(activityItems: eventsString,
                                                  applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
}

extension EventsViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = viewModel.events[indexPath.row]
        switch event {
        case .HKEvent(sampleType: let sampleType,
                      receivedAt: let receivedAt,
                      applicationState: let applicationState,
                      payload: let payload):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HKEventCell", for: indexPath) as? HKEventCell else {
                preconditionFailure("Expected a SleepCell")
            }
            cell.sampleTypeLabel.text = sampleType
            cell.dateLabel.text = DateFormatter.localizedString(from: receivedAt, dateStyle: .medium, timeStyle: .medium)
            cell.applicationStateLabel.text = "Received in app state: \(applicationState)"
            cell.payloadLabel.text = String(describing: payload)
            return cell
        case .AppEvent(receivedAt: let receivedAt,
                       appEvent: let appEvent):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AppEventCell", for: indexPath) as? AppEventCell else {
                preconditionFailure("Expected a StepCountCell")
            }
            cell.dateLabel.text = DateFormatter.localizedString(from: receivedAt, dateStyle: .medium, timeStyle: .medium)
            cell.appEventLabel.text = appEvent
            return cell
        }
    }
}

extension EventsViewController: UITableViewDelegate {}

