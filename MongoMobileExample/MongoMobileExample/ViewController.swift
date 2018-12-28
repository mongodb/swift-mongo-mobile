//
//  ViewController.swift
//  MongoMobileExample
//
//  Created by Jason Flax on 27/12/2018.
//  Copyright © 2018 org.mongodb. All rights reserved.
//

import UIKit
import MongoMobile

private let coll = try! client.db("test").collection("example")

class ViewController: UIViewController {
    @IBOutlet weak var infoLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func deleteTap(_ sender: Any) {
        try? coll.deleteMany([:])
        infoLabel.text = nil
    }

    @IBAction func insertTap(_ sender: Any) {
        try? coll.insertOne([:])
        infoLabel.text = try! coll.find().next()?.canonicalExtendedJSON
    }
}

