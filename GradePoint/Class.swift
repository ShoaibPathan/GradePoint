//
//  Class.swift
//  GradePoint
//
//  Created by Luis Padron on 10/23/16.
//  Copyright © 2016 Luis Padron. All rights reserved.
//

import RealmSwift
import UIKit

class Class: Object {
    
    // MARK: - Properties
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var classType: ClassType = .college
    @objc dynamic var creditHours = 3
    @objc dynamic var semester: Semester?
    @objc dynamic var grade: Grade?
    @objc dynamic var isFavorite: Bool = false
    var rubrics = List<Rubric>()
    var assignments = List<Assignment>()
    @objc dynamic var colorData = Data()
    
    // MARK: - Initializers
    
    /// Used to create an in-progress class
    convenience init(name: String, classType: ClassType, creditHours: Int, semester: Semester, rubrics:  List<Rubric>) {
        self.init()
        self.name = name
        self.classType = classType
        self.creditHours = creditHours
        self.semester = semester
        self.rubrics = rubrics
        self.colorData = UIColor.randomPastel.toData()
        self.grade = Grade(score: 0.0)
    }
    
    /// Used to create a previous class
    convenience init(name: String, classType: ClassType, creditHours: Int, semester: Semester,  grade: Grade) {
        self.init()
        self.name = name
        self.classType = classType
        self.creditHours = creditHours
        self.semester = semester
        self.grade = grade
        self.colorData = UIColor.randomPastel.toData()
    }
    
    // MARK: - Overrides
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["color"]
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the score when assignments are already grouped,
    /// SIDE EFFECT: -> Updates the Grade for the sent in class object
    public static func calculateScore(for groupedAssignments: [[Assignment]], in classObj: Class) -> CGFloat {
        let score = Class.calculateScore(for: groupedAssignments)
        
        // Also update the models Grade.score property in the DB, if its different
        if classObj.grade!.score != score {
            try! Realm().write {
                classObj.grade?.score = score
                classObj.grade?.gradeLetter = Grade.gradeLetter(forScore: score)
            }
        }
        
        return CGFloat(score)
    }
    
    /// Calculates the score if only have a class object
    /// SIDE EFFECT: -> Updates the Grade for the sent in class object
    public static func calculateScore(in classObj: Class) -> CGFloat {
        let rubrics = Array(classObj.rubrics)
        let groupedAssignments = rubrics.map { Array(classObj.assignments.filter("associatedRubric = %@", $0)) }
        
        let score = Class.calculateScore(for: groupedAssignments)
        
        // Also update the models Grade.score property in the DB, if its different
        if classObj.grade!.score != score {
            try! Realm().write {
                classObj.grade?.score = score
                classObj.grade?.gradeLetter = Grade.gradeLetter(forScore: score)
            }
        }
        
        return CGFloat(score)
    }
    
    /// Helper method to reduce code use between the two public static methods
    private static func calculateScore(for groupedAssignments: [[Assignment]]) -> Double {
        var weights = 0.0
        var totalScore = 0.0
        
        for assignments in groupedAssignments {
            if assignments.count == 0 { continue }
            weights += assignments[0].associatedRubric!.weight
            
            var sumTotal = 0.0
            for assignment in assignments { sumTotal += assignment.score }
            
            sumTotal /= Double(assignments.count)
            totalScore += assignments[0].associatedRubric!.weight * sumTotal
        }
        
        return Double(totalScore / weights).roundedUpTo(2)
    }
    
    
    // MARK: - Computed Properties
    
    /// Returns the color after getting it from the color data
    var color: UIColor { get { return NSKeyedUnarchiver.unarchiveObject(with: self.colorData) as! UIColor } }
    
    /// Returns whether or not the class is inprogress or not
    /// Does so by checking whether or not at least 1 rubric has been added, if this is false then
    /// it must be a Previous Class due to the fact previous classes cannot have rubrics
    var isClassInProgress: Bool { get { return self.rubrics.count > 0 } }
    
}
