//
//  NetworkingRequester+Async.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Combine
import Foundation

extension NetworkingRequesterType {
    func execute<T: Decodable>(request: NetworkingTargetType) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            let publisher: AnyPublisher<T, NetworkError> = execute(request: request)
            cancellable = publisher
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        _ = cancellable // retain until completion fires
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}
