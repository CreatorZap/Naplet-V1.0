import SwiftUI
import PhotosUI

// MARK: - Edit Baby Profile View
struct EditBabyProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditBabyProfileViewModel
    @State private var showRemovePhotoAlert = false

    // Callback when baby is deleted
    var onDelete: (() -> Void)?

    init(baby: Baby, onDelete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditBabyProfileViewModel(baby: baby))
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: NapletSpacing.xl) {
                        // Photo Section
                        photoSection

                        // Form Fields
                        formSection

                        // Age Display
                        ageSection

                        // Save Button
                        saveButton

                        // Delete Button (only for owner)
                        if viewModel.canEdit {
                            deleteButton
                        }

                        Spacer(minLength: 50)
                    }
                    .padding(NapletSpacing.lg)
                }

                // Loading Overlay
                if viewModel.isLoading || viewModel.isSaving {
                    loadingOverlay
                }
            }
            .background(NapletColors.background)
            .navigationTitle("editBaby.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NapletColors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(NapletColors.textMuted)
                    }
                }
            }
            .alert("common.error".localized, isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(L10n.Common.ok.localized) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("editBaby.removePhoto.title".localized, isPresented: $showRemovePhotoAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.remove".localized, role: .destructive) {
                    Task {
                        await viewModel.removePhoto()
                    }
                }
            } message: {
                Text("editBaby.removePhoto.message".localized)
            }
            .alert("editBaby.delete.title".localized, isPresented: $viewModel.showDeleteConfirmation) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("editBaby.delete.confirm".localized, role: .destructive) {
                    Task {
                        if await viewModel.deleteBaby() {
                            onDelete?()
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("editBaby.delete.message".localized)
            }
            .onChange(of: viewModel.imagePickerItem) {
                if viewModel.imagePickerItem != nil {
                    Task {
                        await viewModel.handleSelectedPhoto()
                    }
                }
            }
        }
    }

    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: NapletSpacing.md) {
            // Photo with picker
            PhotosPicker(selection: $viewModel.imagePickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    // Photo or placeholder
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(NapletColors.gradientPrimary, lineWidth: 3)
                            )
                    } else if let photoURL = viewModel.photoURL,
                              let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                babyPlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(NapletColors.gradientPrimary, lineWidth: 3)
                                    )
                            case .failure:
                                babyPlaceholder
                            @unknown default:
                                babyPlaceholder
                            }
                        }
                    } else {
                        babyPlaceholder
                    }

                    // Camera badge
                    Circle()
                        .fill(NapletColors.primaryPurple)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                        .offset(x: -4, y: -4)
                }
            }
            .disabled(viewModel.isSaving)

            // Change/Remove buttons
            HStack(spacing: NapletSpacing.md) {
                PhotosPicker(selection: $viewModel.imagePickerItem, matching: .images) {
                    Text("editBaby.changePhoto".localized)
                        .font(NapletTypography.callout())
                        .foregroundColor(NapletColors.primaryPurple)
                }
                .disabled(viewModel.isSaving)

                if viewModel.photoURL != nil || viewModel.selectedImage != nil {
                    Text("•")
                        .foregroundColor(NapletColors.textMuted)

                    Button("editBaby.removePhoto".localized) {
                        showRemovePhotoAlert = true
                    }
                    .font(NapletTypography.callout())
                    .foregroundColor(NapletColors.error)
                    .disabled(viewModel.isSaving)
                }
            }

            // Success message
            if let success = viewModel.successMessage {
                Text(success)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.success)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.successMessage)
    }

    // MARK: - Baby Placeholder
    private var babyPlaceholder: some View {
        Circle()
            .fill(NapletColors.backgroundTertiary)
            .frame(width: 120, height: 120)
            .overlay(
                Text(viewModel.baby.initial)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
            )
            .overlay(
                Circle()
                    .stroke(NapletColors.textMuted.opacity(0.3), lineWidth: 2)
            )
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: NapletSpacing.md) {
            // Name Field
            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text("editBaby.name".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)

                TextField("editBaby.name.placeholder".localized, text: $viewModel.name)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(12)
                    .disabled(viewModel.isSaving)

                if !viewModel.isNameValid && !viewModel.name.isEmpty {
                    Text("editBaby.name.error".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.error)
                }
            }

            // Birth Date Field
            VStack(alignment: .leading, spacing: NapletSpacing.xs) {
                Text("editBaby.birthDate".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)

                DatePicker(
                    "",
                    selection: $viewModel.birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(NapletSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NapletColors.backgroundSecondary)
                .cornerRadius(12)
                .disabled(viewModel.isSaving)
            }

            // Gender Field
            VStack(alignment: .leading, spacing: NapletSpacing.sm) {
                Text("editBaby.gender".localized)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)

                HStack(spacing: NapletSpacing.sm) {
                    genderOption(gender: .female, label: "editBaby.gender.female".localized)
                    genderOption(gender: .male, label: "editBaby.gender.male".localized)
                    genderOption(gender: nil, label: "editBaby.gender.notSpecified".localized)
                }
            }
        }
        .padding(NapletSpacing.lg)
        .background(NapletColors.backgroundTertiary)
        .cornerRadius(16)
    }

    // MARK: - Gender Option
    private func genderOption(gender: Baby.Gender?, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.gender = gender
            }
        } label: {
            HStack(spacing: NapletSpacing.xs) {
                Circle()
                    .stroke(viewModel.gender == gender ? NapletColors.primaryPurple : NapletColors.textMuted.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(viewModel.gender == gender ? NapletColors.primaryPurple : Color.clear)
                            .frame(width: 12, height: 12)
                    )

                Text(label)
                    .font(NapletTypography.subheadline())
                    .foregroundColor(viewModel.gender == gender ? NapletColors.primaryPurple : NapletColors.textSecondary)
            }
            .padding(.vertical, NapletSpacing.sm)
            .padding(.horizontal, NapletSpacing.md)
            .background(viewModel.gender == gender ? NapletColors.primaryPurple.opacity(0.1) : NapletColors.backgroundSecondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
    }

    // MARK: - Age Section
    private var ageSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("editBaby.age".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)

            HStack {
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 20))
                    .foregroundColor(NapletColors.primaryPurple)

                Text(viewModel.calculatedAge)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()
            }
            .padding(NapletSpacing.md)
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(12)
        }
        .padding(NapletSpacing.lg)
        .background(NapletColors.backgroundTertiary)
        .cornerRadius(16)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        NapletButton(
            "editBaby.save".localized,
            style: .primary,
            isLoading: viewModel.isSaving,
            isFullWidth: true
        ) {
            Task {
                if await viewModel.saveChanges() {
                    dismiss()
                }
            }
        }
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.5)
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button {
            viewModel.showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("editBaby.delete".localized)
            }
            .font(NapletTypography.body())
            .foregroundColor(NapletColors.error)
            .frame(maxWidth: .infinity)
            .padding(NapletSpacing.md)
        }
        .disabled(viewModel.isSaving)
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: NapletSpacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(NapletColors.primaryPurple)

                Text(L10n.Common.loading.localized)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
            }
            .padding(NapletSpacing.xl)
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview
#Preview {
    EditBabyProfileView(baby: Baby.preview)
}
