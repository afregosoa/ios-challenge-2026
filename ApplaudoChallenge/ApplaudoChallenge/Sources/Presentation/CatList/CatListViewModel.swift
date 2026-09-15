//
//  CatListViewModel.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Foundation
import NetworkLayer

@Observable
final class CatListViewModel {
    var breeds: [CatBreed] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var searchText = ""

    private var currentPage = 0
    private let pageSize = 15
    private var hasMorePages = true
    private var isFetchingPage = false

    var filteredBreeds: [CatBreed] {
        guard !searchText.isEmpty else { return breeds }
        return breeds.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.origin?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private let service: CatBreedServiceProtocol

    init(service: CatBreedServiceProtocol = CatBreedService()) {
        self.service = service
    }

    func loadBreeds() async {
        guard !isFetchingPage else { return }
        isFetchingPage = true
        isLoading = true
        errorMessage = nil
        do {
            let result = try await service.fetchBreeds(page: 0, limit: pageSize)
            breeds = result
            currentPage = 0
            hasMorePages = result.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        isFetchingPage = false
    }

    func loadMoreIfNeeded(currentItem: CatBreed) async {
        guard searchText.isEmpty,
              !isFetchingPage,
              hasMorePages else { return }

        let threshold = max(breeds.count - 3, 0)
        guard let index = breeds.firstIndex(where: { $0.id == currentItem.id }),
              index >= threshold else { return }

        await loadNextPage()
    }

    private func loadNextPage() async {
        isFetchingPage = true
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let result = try await service.fetchBreeds(page: nextPage, limit: pageSize)
            breeds.append(contentsOf: result)
            currentPage = nextPage
            hasMorePages = result.count == pageSize
        } catch {
            // Existing breeds remain visible; next scroll attempt will retry.
        }
        isLoadingMore = false
        isFetchingPage = false
    }
}
