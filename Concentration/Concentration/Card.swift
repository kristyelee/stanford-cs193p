//
//  Card.swift
//  Concentration
//
//  Created by Kristy Lee on 7/13/19.
//  Copyright © 2019 Kristy Lee. All rights reserved.
//

import Foundation
//structs get a free initializer
struct Card {
    
   // var hashValue: Int { return identifier }
    /*
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    */
    static func ==(lhs: Card, rhs: Card) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var isFaceUp = false
    var isMatched = false
    var identifier: Int
    
    private static var identifierFactory = 0
    
    private static func getUniqueIdentifier() -> Int {
        identifierFactory += 1
        return identifierFactory
    }
    
    
    init() {
        self.identifier = Card.getUniqueIdentifier()
    }
}
