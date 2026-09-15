//
//  MyCatsTabView.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import SwiftUI
import SwiftData

struct MyCatsTabView: View {
    @Query(sort: \SavedCat.createdAt, order: .reverse) private var cats: [SavedCat]

    var body: some View {
        List {
            addCatSection
            myCatsSection
        }
        .listStyle(.plain)
        .navigationTitle("My Collection")
        .background(AppTheme.Colors.background)
    }

    // MARK: - Subviews

    private var addCatSection: some View {
        Section {
            NavigationLink(destination: AddCatView()) {
                AppCard(
                    title: "Add New Cat",
                    subtitle: "Fill in a quick guided form",
                    imageSystemName: "plus.circle",
                    showChevron: false
                )
            }
            .listRowInsets(EdgeInsets(top: AppTheme.Spacing.sm, leading: AppTheme.Spacing.md, bottom: AppTheme.Spacing.sm, trailing: AppTheme.Spacing.md))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var myCatsSection: some View {
        Section {
            if cats.isEmpty {
                EmptyStateView(
                    systemImage: "cat",
                    title: "No Cats Yet",
                    message: "Cats you register will appear here."
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(cats) { cat in
                    catRow(cat)
                }
            }
        } header: {
            SectionHeader(
                title: "My Cats",
                subtitle: cats.isEmpty ? nil : "\(cats.count) \(cats.count == 1 ? "cat" : "cats") registered",
                systemImage: "heart.fill"
            )
            .padding(.vertical, AppTheme.Spacing.xs)
        }
    }

    private func catRow(_ cat: SavedCat) -> some View {
        AppCard(
            title: cat.name,
            subtitle: "\(cat.breed) · \(cat.age) \(cat.age == 1 ? "yr" : "yrs")",
            imageSystemName: "cat.fill",
            showChevron: false
        )
        .listRowInsets(EdgeInsets(top: AppTheme.Spacing.sm, leading: AppTheme.Spacing.md, bottom: AppTheme.Spacing.sm, trailing: AppTheme.Spacing.md))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MyCatsTabView()
    }
    .modelContainer(for: SavedCat.self, inMemory: true)
}
