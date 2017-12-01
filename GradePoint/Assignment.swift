//
//  Assignment.swift
//  GradePoint
//
//  Created by Luis Padron on 12/5/16.
//  Copyright © 2016 Luis Padron. All rights reserved.
//

import Foundation
import RealmSwift

class Assignment: Object {
    
    // MARK: - Properties
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var date = Date()
    @objc dynamic var score: Double = 0.0
    @objc dynamic var rubric: Rubric?

    let parentClass = LinkingObjects(fromType: Class.self, property: "assignments")
    
    // MARK: - Initializers
    
    convenience init(name: String, date: Date, score: Double, associatedRubric: Rubric) {
        self.init()
        
        // Assign values
        self.name = name
        self.date = date
        self.score = score
        self.rubric = associatedRubric
    }
    
    // MARK: - Overrides
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
