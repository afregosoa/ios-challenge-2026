//
//  CatDetailView.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import SwiftUI
import NetworkLayer

struct CatDetailView: View {
    let breed: CatBreed

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(height: 280)
                    .overlay(heroImage)
                    .clipped()
                detailContent
            }
        }
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.large)
        .ignoresSafeArea(edges: .top)
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            metaLabels
            Divider()
            if let description = breed.description {
                section(title: "About") {
                    Text(description)
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            if let temperament = breed.temperament {
                section(title: "Temperament") {
                    Text(temperament)
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.xl)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var heroImage: some View {
        if let urlString = breed.image?.url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    imagePlaceholder
                }
            }
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        AppTheme.Colors.surface
            .overlay(
                Image(systemName: "cat")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.4))
            )
    }

    @ViewBuilder
    private var metaLabels: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            if let origin = breed.origin {
                Label(origin, systemImage: "mappin.and.ellipse")
            }
            if let lifeSpan = breed.lifeSpan {
                Label("\(lifeSpan) yrs", systemImage: "heart")
            }
            if let metric = breed.weight?.metric {
                Label("\(metric) kg", systemImage: "scalemass")
            }
        }
        .font(AppTheme.Fonts.caption)
        .foregroundColor(AppTheme.Colors.textSecondary)
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Fonts.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
            content()
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        CatDetailView(breed: .preview)
    }
}

private extension CatBreed {
    static let preview = CatBreed(
        id: "abys",
        name: "Abyssinian",
        temperament: "Active, Energetic, Independent, Intelligent, Gentle",
        origin: "Egypt",
        description: "The Abyssinian is easy to care for and a joy to have in your home. They are affectionate cats and love both people and other animals.",
        lifeSpan: "14 - 15",
        weight: CatBreedWeight(imperial: "7 - 10", metric: "3 - 5")
    )
}
