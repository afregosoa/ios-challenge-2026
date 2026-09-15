//
//  SavedCat.swift
//  ApplaudoChallenge
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Foundation
import SwiftData

// MARK: - Saved Cat

@Model
final class SavedCat {
    var id: UUID
    var name: String
    var breed: String
    var age: Int
    var notes: String
    var createdAt: Date

    init(name: String, breed: String, age: Int, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.breed = breed
        self.age = age
        self.notes = notes
        self.createdAt = Date()
    }
}
