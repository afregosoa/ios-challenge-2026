import Testing
import Combine
import Foundation
import NetworkLayer
@testable import ApplaudoChallenge

// MARK: - Mocks

private struct MockCatBreedService: CatBreedServiceProtocol {
    var breeds: [CatBreed]
    var error: Error?

    init(breeds: [CatBreed] = [], error: Error? = nil) {
        self.breeds = breeds
        self.error = error
    }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], NetworkError> {
        if let error {
            return Fail(error: NetworkError.unknown(underlying: error))
                .eraseToAnyPublisher()
        }
        return Just(breeds)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}

// Returns a different response for each consecutive call.
private final class PagedMockService: CatBreedServiceProtocol {
    private var callIndex = 0
    private let responses: [[CatBreed]]

    init(responses: [[CatBreed]]) { self.responses = responses }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], NetworkError> {
        defer { callIndex += 1 }
        let result = callIndex < responses.count ? responses[callIndex] : []
        return Just(result)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}

// Succeeds on first call, fails on all subsequent calls.
private final class FailAfterFirstService: CatBreedServiceProtocol {
    private var callIndex = 0
    private let firstPage: [CatBreed]

    init(firstPage: [CatBreed]) { self.firstPage = firstPage }

    func fetchBreeds(page: Int, limit: Int) -> AnyPublisher<[CatBreed], NetworkError> {
        defer { callIndex += 1 }
        if callIndex == 0 {
            return Just(firstPage)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }
        return Fail(error: NetworkError.unknown(underlying: URLError(.notConnectedToInternet)))
            .eraseToAnyPublisher()
    }
}

// MARK: - AddCatViewModel: Name Validation

@Suite("AddCatViewModel — Name Validation")
struct AddCatViewModelNameValidationTests {
    let vm = AddCatViewModel()

    @Test func hiddenBeforeEditing() {
        #expect(vm.nameError == nil)
    }

    @Test func requiredWhenEmpty() {
        vm.nameEdited = true
        vm.name = ""
        #expect(vm.nameError == "Name is required")
    }

    @Test func tooShort() {
        vm.nameEdited = true
        vm.name = "A"
        #expect(vm.nameError == "Name must be at least 2 characters")
    }

    @Test func tooLong() {
        vm.nameEdited = true
        vm.name = String(repeating: "a", count: 31)
        #expect(vm.nameError == "Name must be 30 characters or fewer")
    }

    @Test func invalidCharacters() {
        vm.nameEdited = true
        vm.name = "Cat123"
        #expect(vm.nameError == "Name can only contain letters, spaces, hyphens, and apostrophes")
    }

    @Test func consecutiveSpaces() {
        vm.nameEdited = true
        vm.name = "Mr  Whiskers"
        #expect(vm.nameError == "Name cannot contain consecutive spaces")
    }

    @Test func validPlainName() {
        vm.nameEdited = true
        vm.name = "Whiskers"
        #expect(vm.nameError == nil)
    }

    @Test func validNameWithHyphen() {
        vm.nameEdited = true
        vm.name = "Mr-Whiskers"
        #expect(vm.nameError == nil)
    }

    @Test func validNameWithApostrophe() {
        vm.nameEdited = true
        vm.name = "O'Malley"
        #expect(vm.nameError == nil)
    }
}

// MARK: - AddCatViewModel: Breed Validation

@Suite("AddCatViewModel — Breed Validation")
struct AddCatViewModelBreedValidationTests {
    let vm = AddCatViewModel()

    @Test func hiddenBeforeEditing() {
        #expect(vm.breedError == nil)
    }

    @Test func requiredWhenEmpty() {
        vm.breedEdited = true
        vm.breed = ""
        #expect(vm.breedError == "Breed is required")
    }

    @Test func tooLong() {
        vm.breedEdited = true
        vm.breed = String(repeating: "a", count: 51)
        #expect(vm.breedError == "Breed must be 50 characters or fewer")
    }

    @Test func invalidCharacters() {
        vm.breedEdited = true
        vm.breed = "Persian123"
        #expect(vm.breedError == "Breed can only contain letters and spaces")
    }

    @Test func validBreed() {
        vm.breedEdited = true
        vm.breed = "Scottish Fold"
        #expect(vm.breedError == nil)
    }
}

// MARK: - AddCatViewModel: Navigation

@Suite("AddCatViewModel — Navigation")
struct AddCatViewModelNavigationTests {
    let vm = AddCatViewModel()

    @Test func nextMarksFieldsTouchedOnStep0() {
        vm.next()
        #expect(vm.nameEdited == true)
        #expect(vm.breedEdited == true)
    }

    @Test func nextBlocksAdvanceWhenInvalid() {
        vm.next()
        #expect(vm.currentStep == 0)
    }

    @Test func nextAdvancesWhenStep1Valid() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        vm.next()
        #expect(vm.currentStep == 1)
    }

    @Test func backDecrementsStep() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        vm.next()
        vm.back()
        #expect(vm.currentStep == 0)
    }

    @Test func backDoesNotGoBelowZero() {
        vm.back()
        #expect(vm.currentStep == 0)
    }

    @Test func resetClearsAllState() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        vm.nameEdited = true
        vm.breedEdited = true
        vm.next()
        vm.reset()

        #expect(vm.currentStep == 0)
        #expect(vm.name == "")
        #expect(vm.breed == "")
        #expect(vm.age == 1)
        #expect(vm.notes == "")
        #expect(vm.nameEdited == false)
        #expect(vm.breedEdited == false)
        #expect(vm.isSaved == false)
    }
}

// MARK: - CatListViewModel

@MainActor
@Suite("CatListViewModel")
struct CatListViewModelTests {

    @Test func loadBreedsSetsBreeds() async {
        let breeds = [CatBreed(id: "abys", name: "Abyssinian")]
        let vm = CatListViewModel(service: MockCatBreedService(breeds: breeds))
        vm.loadBreeds()
        await Task.yield()
        #expect(vm.breeds.count == 1)
        #expect(vm.breeds.first?.name == "Abyssinian")
    }

    @Test func loadBreedsSetsErrorOnFailure() async {
        let vm = CatListViewModel(service: MockCatBreedService(error: URLError(.notConnectedToInternet)))
        vm.loadBreeds()
        await Task.yield()
        #expect(vm.errorMessage != nil)
        #expect(vm.breeds.isEmpty)
    }

    @Test func isLoadingFalseAfterLoad() async {
        let vm = CatListViewModel(service: MockCatBreedService())
        vm.loadBreeds()
        await Task.yield()
        #expect(vm.isLoading == false)
    }

    @Test func searchFiltersByName() async {
        let breeds = [
            CatBreed(id: "abys", name: "Abyssinian", origin: "Egypt"),
            CatBreed(id: "pers", name: "Persian", origin: "Iran")
        ]
        let vm = CatListViewModel(service: MockCatBreedService(breeds: breeds))
        vm.loadBreeds()
        await Task.yield()
        vm.searchText = "Persian"
        #expect(vm.filteredBreeds.count == 1)
        #expect(vm.filteredBreeds.first?.name == "Persian")
    }

    @Test func searchFiltersByOrigin() async {
        let breeds = [
            CatBreed(id: "abys", name: "Abyssinian", origin: "Egypt"),
            CatBreed(id: "pers", name: "Persian", origin: "Iran")
        ]
        let vm = CatListViewModel(service: MockCatBreedService(breeds: breeds))
        vm.loadBreeds()
        await Task.yield()
        vm.searchText = "Egypt"
        #expect(vm.filteredBreeds.count == 1)
        #expect(vm.filteredBreeds.first?.id == "abys")
    }

    @Test func emptySearchReturnsAllBreeds() async {
        let breeds = [
            CatBreed(id: "abys", name: "Abyssinian"),
            CatBreed(id: "pers", name: "Persian")
        ]
        let vm = CatListViewModel(service: MockCatBreedService(breeds: breeds))
        vm.loadBreeds()
        await Task.yield()
        vm.searchText = ""
        #expect(vm.filteredBreeds.count == 2)
    }
}

// MARK: - AddCatViewModel: Name Validation Boundaries

@Suite("AddCatViewModel — Name Boundaries")
struct AddCatViewModelNameBoundaryTests {
    let vm = AddCatViewModel()

    @Test func whitespaceOnlyIsRequired() {
        vm.nameEdited = true
        vm.name = "   "
        #expect(vm.nameError == "Name is required")
    }

    @Test func twoCharsBoundaryIsValid() {
        vm.nameEdited = true
        vm.name = "Ab"
        #expect(vm.nameError == nil)
    }

    @Test func thirtyCharsBoundaryIsValid() {
        vm.nameEdited = true
        vm.name = String(repeating: "a", count: 30)
        #expect(vm.nameError == nil)
    }

    @Test func thirtyOneCharsIsInvalid() {
        vm.nameEdited = true
        vm.name = String(repeating: "a", count: 31)
        #expect(vm.nameError != nil)
    }
}

// MARK: - AddCatViewModel: Breed Validation Boundaries

@Suite("AddCatViewModel — Breed Boundaries")
struct AddCatViewModelBreedBoundaryTests {
    let vm = AddCatViewModel()

    @Test func whitespaceOnlyIsRequired() {
        vm.breedEdited = true
        vm.breed = "   "
        #expect(vm.breedError == "Breed is required")
    }

    @Test func fiftyCharsBoundaryIsValid() {
        vm.breedEdited = true
        vm.breed = String(repeating: "a", count: 50)
        #expect(vm.breedError == nil)
    }

    @Test func fiftyOneCharsIsInvalid() {
        vm.breedEdited = true
        vm.breed = String(repeating: "a", count: 51)
        #expect(vm.breedError != nil)
    }
}

// MARK: - AddCatViewModel: isStep1Valid Combinations

@Suite("AddCatViewModel — Step 1 Validity")
struct AddCatViewModelStep1ValidityTests {
    let vm = AddCatViewModel()

    @Test func bothEmptyIsInvalid() {
        #expect(vm.isStep1Valid == false)
    }

    @Test func onlyNameValidIsInvalid() {
        vm.name = "Whiskers"
        #expect(vm.isStep1Valid == false)
    }

    @Test func onlyBreedValidIsInvalid() {
        vm.breed = "Persian"
        #expect(vm.isStep1Valid == false)
    }

    @Test func bothValidIsValid() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        #expect(vm.isStep1Valid == true)
    }
}

// MARK: - AddCatViewModel: Multi-step Navigation

@Suite("AddCatViewModel — Multi-step Navigation")
struct AddCatViewModelMultiStepTests {
    let vm = AddCatViewModel()

    @Test func nextFromStep1AdvancesToStep2() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        vm.next()            // step 0 → 1
        vm.next()            // step 1 → 2 (age is always valid)
        #expect(vm.currentStep == 2)
    }

    @Test func backFromStep2ReturnsToStep1() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        vm.next()
        vm.next()
        vm.back()
        #expect(vm.currentStep == 1)
    }

    @Test func nextOnLastStepDoesNotExceed() {
        vm.name = "Whiskers"
        vm.breed = "Persian"
        vm.next()
        vm.next()
        vm.next()            // already on last step — should stay
        #expect(vm.currentStep == 2)
    }
}

// MARK: - CatListViewModel: Pagination

@MainActor
@Suite("CatListViewModel — Pagination")
struct CatListViewModelPaginationTests {
    private let pageSize = 15

    private func makeBreeds(count: Int, prefix: String = "") -> [CatBreed] {
        (0..<count).map { CatBreed(id: "\(prefix)\($0)", name: "Cat \(prefix)\($0)") }
    }

    @Test func partialPagePreventsLoadingMore() async {
        let partial = makeBreeds(count: 5)
        let vm = CatListViewModel(service: MockCatBreedService(breeds: partial))
        vm.loadBreeds()
        await Task.yield()
        #expect(vm.breeds.count == 5)

        let last = vm.breeds.last!
        vm.loadMoreIfNeeded(currentItem: last)
        await Task.yield()
        #expect(vm.breeds.count == 5)
    }

    @Test func fullPageLoadsMoreWhenNearEnd() async {
        let firstPage = makeBreeds(count: pageSize)
        let secondPage = makeBreeds(count: 3, prefix: "p2-")
        let service = PagedMockService(responses: [firstPage, secondPage])
        let vm = CatListViewModel(service: service)
        vm.loadBreeds()
        await Task.yield()
        #expect(vm.breeds.count == pageSize)

        let last = vm.breeds.last!
        vm.loadMoreIfNeeded(currentItem: last)
        await Task.yield()
        #expect(vm.breeds.count == pageSize + 3)
    }

    @Test func searchActivePreventsPagination() async {
        let firstPage = makeBreeds(count: pageSize)
        let secondPage = makeBreeds(count: 3, prefix: "p2-")
        let service = PagedMockService(responses: [firstPage, secondPage])
        let vm = CatListViewModel(service: service)
        vm.loadBreeds()
        await Task.yield()

        vm.searchText = "Cat"
        let last = vm.breeds.last!
        vm.loadMoreIfNeeded(currentItem: last)
        await Task.yield()
        #expect(vm.breeds.count == pageSize)
    }

    @Test func paginationErrorPreservesExistingBreeds() async {
        let firstPage = makeBreeds(count: pageSize)
        let service = FailAfterFirstService(firstPage: firstPage)
        let vm = CatListViewModel(service: service)
        vm.loadBreeds()
        await Task.yield()
        #expect(vm.breeds.count == pageSize)

        let last = vm.breeds.last!
        vm.loadMoreIfNeeded(currentItem: last)
        await Task.yield()
        #expect(vm.breeds.count == pageSize)
        #expect(vm.isLoadingMore == false)
    }
}
