//
//  AddCatViewModel.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Foundation
import SwiftData

@Observable
final class AddCatViewModel {

    // MARK: - Step State

    var currentStep = 0
    let totalSteps = 3
    let stepTitles = ["Basic Info", "Details", "Review"]

    // MARK: - Form Fields

    var name = ""
    var breed = ""
    var age = 1
    var notes = ""

    // MARK: - UI State

    var isSaved = false

    // MARK: - Touched State

    var nameEdited = false
    var breedEdited = false

    // MARK: - Validation Errors

    private static let nameAllowedCharacters = CharacterSet.letters
        .union(.init(charactersIn: " '-"))
    private static let breedAllowedCharacters = CharacterSet.letters
        .union(.init(charactersIn: " "))

    var nameError: String? {
        guard nameEdited else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Name is required" }
        if trimmed.count < 2 { return "Name must be at least 2 characters" }
        if trimmed.count > 30 { return "Name must be 30 characters or fewer" }
        if trimmed.rangeOfCharacter(from: Self.nameAllowedCharacters.inverted) != nil {
            return "Name can only contain letters, spaces, hyphens, and apostrophes"
        }
        if trimmed.contains("  ") { return "Name cannot contain consecutive spaces" }
        return nil
    }

    var breedError: String? {
        guard breedEdited else { return nil }
        let trimmed = breed.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Breed is required" }
        if trimmed.count > 50 { return "Breed must be 50 characters or fewer" }
        if trimmed.rangeOfCharacter(from: Self.breedAllowedCharacters.inverted) != nil {
            return "Breed can only contain letters and spaces"
        }
        return nil
    }

    // MARK: - Step Validity

    var isStep1Valid: Bool {
        let nameTrimmed = name.trimmingCharacters(in: .whitespaces)
        let breedTrimmed = breed.trimmingCharacters(in: .whitespaces)
        guard nameTrimmed.count >= 2,
              nameTrimmed.count <= 30,
              nameTrimmed.rangeOfCharacter(from: Self.nameAllowedCharacters.inverted) == nil,
              !nameTrimmed.contains("  "),
              !breedTrimmed.isEmpty,
              breedTrimmed.count <= 50,
              breedTrimmed.rangeOfCharacter(from: Self.breedAllowedCharacters.inverted) == nil
        else { return false }
        return true
    }

    var isStep2Valid: Bool { age >= 1 }

    var canProceed: Bool {
        switch currentStep {
        case 0: return isStep1Valid
        case 1: return isStep2Valid
        default: return true
        }
    }

    // MARK: - Actions

    func next() {
        if currentStep == 0 {
            nameEdited = true
            breedEdited = true
        }
        guard canProceed, currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func back() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func save(in context: ModelContext) {
        let cat = SavedCat(name: name, breed: breed, age: age, notes: notes)
        context.insert(cat)
        isSaved = true
    }

    func reset() {
        currentStep = 0
        name = ""
        breed = ""
        age = 1
        notes = ""
        isSaved = false
        nameEdited = false
        breedEdited = false
    }
}
