//
//  AddCatView.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import SwiftUI
import SwiftData

struct AddCatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AddCatViewModel()

    var body: some View {
        if viewModel.isSaved {
            successView
        } else {
            formView
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 0) {
            StepperIndicator(
                currentStep: viewModel.currentStep,
                totalSteps: viewModel.totalSteps,
                stepTitles: viewModel.stepTitles
            )
            .padding(.vertical, AppTheme.Spacing.lg)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    stepContent
                }
                .padding(AppTheme.Spacing.md)
            }

            Divider()
            navigationButtons
                .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("Add Cat")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 0: step1
        case 1: step2
        default: step3
        }
    }

    private var step1: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "Basic Info",
                subtitle: "Tell us about your cat",
                systemImage: "cat"
            )
            AppTextField(
                label: "Cat Name",
                placeholder: "e.g. Whiskers",
                text: $viewModel.name,
                errorMessage: viewModel.nameError,
                icon: "pencil"
            )
            .onChange(of: viewModel.name) { viewModel.nameEdited = true }
            AppTextField(
                label: "Breed",
                placeholder: "e.g. Persian",
                text: $viewModel.breed,
                errorMessage: viewModel.breedError,
                icon: "list.bullet"
            )
            .onChange(of: viewModel.breed) { viewModel.breedEdited = true }
        }
    }

    private var step2: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "Details",
                subtitle: "A bit more information",
                systemImage: "info.circle"
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Age (years)")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                HStack {
                    Text("\(viewModel.age) \(viewModel.age == 1 ? "year" : "years") old")
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Stepper("", value: $viewModel.age, in: 1...30)
                        .labelsHidden()
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Notes (optional)")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                TextEditor(text: $viewModel.notes)
                    .font(AppTheme.Fonts.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(minHeight: 100)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
            }
        }
    }

    private var step3: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "Review",
                subtitle: "Confirm your cat's information",
                systemImage: "checkmark.circle"
            )

            VStack(spacing: 0) {
                reviewRow(label: "Name", value: viewModel.name)
                Divider().padding(.leading, AppTheme.Spacing.md)
                reviewRow(label: "Breed", value: viewModel.breed)
                Divider().padding(.leading, AppTheme.Spacing.md)
                reviewRow(label: "Age", value: "\(viewModel.age) \(viewModel.age == 1 ? "year" : "years")")
                if !viewModel.notes.isEmpty {
                    Divider().padding(.leading, AppTheme.Spacing.md)
                    reviewRow(label: "Notes", value: viewModel.notes)
                }
            }
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if viewModel.currentStep > 0 {
                AppButton(title: "Back", style: .secondary) {
                    viewModel.back()
                }
            }

            if viewModel.currentStep < viewModel.totalSteps - 1 {
                AppButton(
                    title: "Next",
                    style: .primary,
                    isEnabled: viewModel.canProceed
                ) {
                    viewModel.next()
                }
            } else {
                AppButton(title: "Save Cat", style: .primary) {
                    viewModel.save(in: modelContext)
                }
            }
        }
    }

    // MARK: - Success State

    private var successView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(AppTheme.Colors.success)

            Text("Cat Added!")
                .font(AppTheme.Fonts.largeTitle)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("\(viewModel.name) has been saved to your collection.")
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()

            AppButton(title: "Add Another Cat", style: .primary) {
                viewModel.reset()
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddCatView()
    }
    .modelContainer(for: SavedCat.self, inMemory: true)
}
