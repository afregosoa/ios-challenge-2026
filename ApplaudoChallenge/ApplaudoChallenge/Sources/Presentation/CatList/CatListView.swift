//
//  CatListView.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import SwiftUI
import NetworkLayer

struct CatListView: View {
    @State private var viewModel = CatListViewModel()

    var body: some View {
        contentView
            .navigationTitle("Cat Breeds")
            .searchable(text: $viewModel.searchText, prompt: "Search by name or origin")
            .background(AppTheme.Colors.background)
            .task {
                if viewModel.breeds.isEmpty {
                    await viewModel.loadBreeds()
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            EmptyStateView(
                systemImage: "exclamationmark.triangle",
                title: "Something went wrong",
                message: error,
                buttonTitle: "Retry",
                action: { Task { await viewModel.loadBreeds() } }
            )
        } else if viewModel.filteredBreeds.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No Results",
                message: "No breeds match \"\(viewModel.searchText)\""
            )
        } else {
            breedList
        }
    }

    private var breedList: some View {
        List {
            ForEach(viewModel.filteredBreeds) { breed in
                breedRow(breed)
            }
            if viewModel.isLoadingMore {
                loadingFooter
            }
        }
        .listStyle(.plain)
    }

    private func breedRow(_ breed: CatBreed) -> some View {
        NavigationLink(destination: CatDetailView(breed: breed)) {
            AppCard(
                title: breed.name,
                subtitle: breed.description.map { String($0.prefix(80)) } ?? "",
                imageSystemName: "cat",
                imageURL: breed.image?.url,
                showChevron: false
            )
        }
        .listRowInsets(EdgeInsets(top: AppTheme.Spacing.sm, leading: AppTheme.Spacing.md, bottom: AppTheme.Spacing.sm, trailing: AppTheme.Spacing.md))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .task {
            await viewModel.loadMoreIfNeeded(currentItem: breed)
        }
    }

    private var loadingFooter: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CatListView()
    }
}
