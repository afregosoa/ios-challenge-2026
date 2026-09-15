import Combine
import Foundation
import Moya

// MARK: - Protocol

public protocol CatBreedServiceProtocol {
    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], NetworkError>
}

// MARK: - Implementation

public struct CatBreedService: CatBreedServiceProtocol {
    private let requester: NetworkingRequesterType

    public init() {
        self.requester = NetworkingRequester(provider: .networkingProvider())
    }

    // Internal init for injecting mocks in unit tests.
    init(requester: NetworkingRequesterType) {
        self.requester = requester
    }

    public func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], NetworkError> {
        requester.execute(request: BreedsTarget.getBreeds(page: page, limit: limit))
    }
}
