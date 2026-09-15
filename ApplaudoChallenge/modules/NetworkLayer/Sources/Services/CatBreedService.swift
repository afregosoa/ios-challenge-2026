//
//  CatBreedService.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Foundation
import Moya

// MARK: - Protocol

public protocol CatBreedServiceProtocol {
    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed]
}

// MARK: - Implementation

public struct CatBreedService: CatBreedServiceProtocol {
    private let requester: NetworkingRequesterType

    // Public init uses internal types only inside the module body — no public parameter exposure.
    public init() {
        self.requester = NetworkingRequester(provider: .networkingProvider())
    }

    // Internal init for injecting mocks in unit tests.
    init(requester: NetworkingRequesterType) {
        self.requester = requester
    }

    public func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        try await requester.execute(request: BreedsTarget.getBreeds(page: page, limit: limit))
    }
}
