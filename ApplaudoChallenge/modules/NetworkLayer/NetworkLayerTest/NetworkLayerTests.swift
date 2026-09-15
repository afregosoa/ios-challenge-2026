import Testing
import Foundation
import Combine
@testable import NetworkLayer

// MARK: - Mock

private struct MockNetworkingRequester: NetworkingRequesterType {
    let data: Data
    let error: NetworkError?

    init(data: Data = Data(), error: NetworkError? = nil) {
        self.data = data
        self.error = error
    }

    func execute(request: NetworkingTargetType) -> AnyPublisher<Data, NetworkError> {
        if let error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(data).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
    }
}

// MARK: - CatBreed Decoding

@Suite("CatBreed — JSON Decoding")
struct CatBreedDecodingTests {

    @Test func decodesMinimalResponse() throws {
        let json = #"{"id":"abys","name":"Abyssinian"}"#.data(using: .utf8)!
        let breed = try JSONDecoder().decode(CatBreed.self, from: json)
        #expect(breed.id == "abys")
        #expect(breed.name == "Abyssinian")
        #expect(breed.origin == nil)
        #expect(breed.image == nil)
    }

    @Test func decodesSnakeCaseKeys() throws {
        let json = """
        {
            "id": "abys",
            "name": "Abyssinian",
            "life_span": "14 - 15",
            "affection_level": 5,
            "reference_image_id": "img123",
            "energy_level": 4
        }
        """.data(using: .utf8)!

        let breed = try JSONDecoder().decode(CatBreed.self, from: json)
        #expect(breed.lifeSpan == "14 - 15")
    }

    @Test func decodesNestedWeight() throws {
        let json = """
        {
            "id": "abys",
            "name": "Abyssinian",
            "weight": { "imperial": "7 - 10", "metric": "3 - 5" }
        }
        """.data(using: .utf8)!

        let breed = try JSONDecoder().decode(CatBreed.self, from: json)
        #expect(breed.weight?.imperial == "7 - 10")
        #expect(breed.weight?.metric == "3 - 5")
    }

    @Test func decodesNestedImage() throws {
        let json = """
        {
            "id": "abys",
            "name": "Abyssinian",
            "image": { "id": "img1", "url": "https://example.com/cat.jpg", "width": 800, "height": 600 }
        }
        """.data(using: .utf8)!

        let breed = try JSONDecoder().decode(CatBreed.self, from: json)
        #expect(breed.image?.url == "https://example.com/cat.jpg")
        #expect(breed.image?.width == 800)
    }

    @Test func decodesArray() throws {
        let json = """
        [
            {"id":"abys","name":"Abyssinian"},
            {"id":"pers","name":"Persian"}
        ]
        """.data(using: .utf8)!

        let breeds = try JSONDecoder().decode([CatBreed].self, from: json)
        #expect(breeds.count == 2)
        #expect(breeds[0].id == "abys")
        #expect(breeds[1].id == "pers")
    }
}

// MARK: - CatBreedService

@Suite("CatBreedService")
struct CatBreedServiceTests {

    @Test func returnsDecodedBreeds() async throws {
        let json = #"[{"id":"abys","name":"Abyssinian"}]"#.data(using: .utf8)!
        let service = CatBreedService(requester: MockNetworkingRequester(data: json))
        let breeds = try await service.fetchBreeds(page: 0, limit: 15)
        #expect(breeds.count == 1)
        #expect(breeds.first?.id == "abys")
    }

    @Test func returnsEmptyArrayForEmptyResponse() async throws {
        let json = "[]".data(using: .utf8)!
        let service = CatBreedService(requester: MockNetworkingRequester(data: json))
        let breeds = try await service.fetchBreeds(page: 0, limit: 15)
        #expect(breeds.isEmpty)
    }

    @Test func throwsOnNetworkError() async {
        let service = CatBreedService(requester: MockNetworkingRequester(
            error: .unknown(underlying: URLError(.notConnectedToInternet))
        ))
        await #expect(throws: (any Error).self) {
            try await service.fetchBreeds(page: 0, limit: 15)
        }
    }

    @Test func throwsOnServerError() async {
        let service = CatBreedService(requester: MockNetworkingRequester(
            error: .serverError(statusCode: 401, data: Data())
        ))
        await #expect(throws: (any Error).self) {
            try await service.fetchBreeds(page: 0, limit: 15)
        }
    }
}


