//
//  Rubric.swift
//  GradePoint
//
//  Created by Luis Padron on 10/23/16.
//  Copyright © 2016 Luis Padron. All rights reserved.
//

import Foundation

struct Rubric {
    var name: String!
    var weight: Double!
    
    init(withName name: String, andWeight weight: Double!) {
        self.name = name
        self.weight = weight
    }
}
