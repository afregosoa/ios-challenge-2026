import Combine
import Foundation
import NetworkLayer

@Observable
final class CatListViewModel {
    var breeds: [CatBreed] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var searchText = ""

    @ObservationIgnored private var currentPage = 0
    @ObservationIgnored private let pageSize = 15
    @ObservationIgnored private var hasMorePages = true
    @ObservationIgnored private var isFetchingPage = false
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

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

    func loadBreeds() {
        guard !isFetchingPage else { return }
        isFetchingPage = true
        isLoading = true
        errorMessage = nil

        service.fetchBreeds(page: 0, limit: pageSize)
            .sink(
                receiveCompletion: { [weak self] completion in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if case .failure(let error) = completion {
                            self.errorMessage = error.localizedDescription
                        }
                        self.isLoading = false
                        self.isFetchingPage = false
                    }
                },
                receiveValue: { [weak self] result in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.breeds = result
                        self.currentPage = 0
                        self.hasMorePages = result.count == self.pageSize
                    }
                }
            )
            .store(in: &cancellables)
    }

    func loadMoreIfNeeded(currentItem: CatBreed) {
        guard searchText.isEmpty,
              !isFetchingPage,
              hasMorePages else { return }

        let threshold = max(breeds.count - 3, 0)
        guard let index = breeds.firstIndex(where: { $0.id == currentItem.id }),
              index >= threshold else { return }

        loadNextPage()
    }

    private func loadNextPage() {
        isFetchingPage = true
        isLoadingMore = true
        let nextPage = currentPage + 1

        service.fetchBreeds(page: nextPage, limit: pageSize)
            .sink(
                receiveCompletion: { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.isLoadingMore = false
                        self.isFetchingPage = false
                    }
                },
                receiveValue: { [weak self] result in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.breeds.append(contentsOf: result)
                        self.currentPage = nextPage
                        self.hasMorePages = result.count == self.pageSize
                    }
                }
            )
            .store(in: &cancellables)
    }
}
