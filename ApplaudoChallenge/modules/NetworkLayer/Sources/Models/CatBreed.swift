//
//  CatBreed.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Foundation

// MARK: - Cat Breed

public struct CatBreed: Decodable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let temperament: String?
    public let origin: String?
    public let description: String?
    public let lifeSpan: String?
    public let image: CatBreedImage?
    public let weight: CatBreedWeight?

    public init(
        id: String, name: String, temperament: String? = nil, origin: String? = nil,
        description: String? = nil, lifeSpan: String? = nil,
        image: CatBreedImage? = nil, weight: CatBreedWeight? = nil
    ) {
        self.id = id; self.name = name; self.temperament = temperament; self.origin = origin
        self.description = description; self.lifeSpan = lifeSpan
        self.image = image; self.weight = weight
    }

    enum CodingKeys: String, CodingKey {
        case id, name, temperament, origin, description
        case lifeSpan = "life_span"
        case image
        case weight
    }
}

// MARK: - Cat Breed Image

public struct CatBreedImage: Decodable, Sendable {
    public let id: String
    public let url: String
    public let width: Int?
    public let height: Int?
}

// MARK: - Cat Breed Weight

public struct CatBreedWeight: Decodable, Sendable {
    public let imperial: String
    public let metric: String

    public init(imperial: String, metric: String) {
        self.imperial = imperial
        self.metric = metric
    }
}
