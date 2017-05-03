//
//  QueryViewController.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 10/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import UIKit

class QueryViewController: UIViewController {

    @IBOutlet weak var sampleTypeControl: UISegmentedControl!
    @IBOutlet weak var queryRangeControl: UISegmentedControl!
    @IBOutlet weak var statisticsOptionControl: UISegmentedControl!
    
    @IBOutlet weak var executeButton: UIButton!
    
    @IBOutlet weak var sampleTypeText: UITextField!
    @IBOutlet weak var statisticsOptionText: UITextField!
    
    @IBOutlet weak var startDateText: UITextField!
    @IBOutlet weak var endDateText: UITextField!
    
    @IBOutlet weak var resultText: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onExecuteButtonPressed(_ sender: Any) {
        
    }

}

