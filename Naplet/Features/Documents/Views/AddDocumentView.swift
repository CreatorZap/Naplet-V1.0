import SwiftUI
import PhotosUI

// MARK: - Add Document View
struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DocumentsViewModel

    // Form State
    @State private var selectedType: DocumentType?
    @State private var title = ""
    @State private var documentNumber = ""
    @State private var issueDate: Date?
    @State private var expirationDate: Date?
    @State private var issuingAuthority = ""
    @State private var notes = ""
    @State private var showIssueDatePicker = false
    @State private var showExpirationDatePicker = false

    // Image Picker
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var isLoadingImages = false

    // Validation
    private var isValid: Bool {
        selectedType != nil && !title.isEmpty
    }

    // State to force re-render on appear
    @State private var isReady = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ensure background is always visible
                NapletColors.background
                    .ignoresSafeArea()

                if isReady {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Document Type Selection
                            documentTypeSection

                            // Document Info
                            documentInfoSection

                            // Dates
                            datesSection

                            // Images
                            imagesSection

                            // Notes
                            notesSection
                        }
                        .padding()
                    }
                    .transition(.opacity)
                } else {
                    ProgressView()
                        .tint(NapletColors.primaryPurple)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isReady)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isReady = true
                }
            }
            .navigationTitle("documents.add.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NapletColors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task { await saveDocument() }
                    }
                    .foregroundColor(isValid ? NapletColors.primaryPurple : NapletColors.textMuted)
                    .disabled(!isValid || viewModel.isLoading)
                }
            }
        }
        .presentationBackground(NapletColors.background)
    }

    // MARK: - Document Type Section

    private var documentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("documents.selectType".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(viewModel.documentTypes) { type in
                    DocumentTypeCard(
                        type: type,
                        isSelected: selectedType?.id == type.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedType = type
                            if title.isEmpty {
                                title = type.localizedName
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Document Info Section

    private var documentInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("documents.info".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("documents.form.title".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    TextField("documents.form.titlePlaceholder".localized, text: $title)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                        .foregroundColor(NapletColors.textPrimary)
                }

                // Document Number
                VStack(alignment: .leading, spacing: 8) {
                    Text("documents.form.number".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    TextField("documents.form.numberPlaceholder".localized, text: $documentNumber)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                        .foregroundColor(NapletColors.textPrimary)
                }

                // Issuing Authority
                VStack(alignment: .leading, spacing: 8) {
                    Text("documents.form.authority".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    TextField("documents.form.authorityPlaceholder".localized, text: $issuingAuthority)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                        .foregroundColor(NapletColors.textPrimary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Dates Section

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("documents.dates".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            VStack(spacing: 16) {
                // Issue Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("documents.form.issueDate".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    Button {
                        showIssueDatePicker.toggle()
                    } label: {
                        HStack {
                            Text(issueDate?.formatted(date: .abbreviated, time: .omitted) ?? "documents.form.selectDate".localized)
                                .foregroundColor(issueDate != nil ? NapletColors.textPrimary : NapletColors.textMuted)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(NapletColors.primaryPurple)
                        }
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                    }

                    if showIssueDatePicker {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { issueDate ?? Date() },
                                set: { issueDate = $0 }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(NapletColors.primaryPurple)
                    }
                }

                // Expiration Date (if type has expiration)
                if selectedType?.hasExpiration == true {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("documents.form.expirationDate".localized)
                            .font(.subheadline)
                            .foregroundColor(NapletColors.textSecondary)

                        Button {
                            showExpirationDatePicker.toggle()
                        } label: {
                            HStack {
                                Text(expirationDate?.formatted(date: .abbreviated, time: .omitted) ?? "documents.form.selectDate".localized)
                                    .foregroundColor(expirationDate != nil ? NapletColors.textPrimary : NapletColors.textMuted)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(NapletColors.primaryPurple)
                            }
                            .padding(12)
                            .background(NapletColors.backgroundTertiary)
                            .cornerRadius(12)
                        }

                        if showExpirationDatePicker {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { expirationDate ?? Date() },
                                    set: { expirationDate = $0 }
                                ),
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .tint(NapletColors.primaryPurple)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Images Section

    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("documents.photos".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)

                Spacer()

                Text("documents.optional".localized)
                    .font(.caption)
                    .foregroundColor(NapletColors.textMuted)
            }

            // Image Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                // Add Button
                PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(NapletColors.primaryPurple)
                        Text("documents.addPhoto".localized)
                            .font(.caption2)
                            .foregroundColor(NapletColors.textSecondary)
                    }
                    .frame(width: 80, height: 80)
                    .background(NapletColors.backgroundTertiary)
                    .cornerRadius(12)
                }

                // Selected Images
                ForEach(loadedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: loadedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            loadedImages.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }

            if isLoadingImages {
                HStack {
                    ProgressView()
                        .tint(NapletColors.primaryPurple)
                    Text("documents.loadingPhotos".localized)
                        .font(.caption)
                        .foregroundColor(NapletColors.textSecondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
        .onChange(of: selectedImages) { _, newItems in
            Task { await loadImages(from: newItems) }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("documents.notes".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            TextField("documents.form.notesPlaceholder".localized, text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(NapletColors.backgroundTertiary)
                .cornerRadius(12)
                .foregroundColor(NapletColors.textPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Actions

    private func loadImages(from items: [PhotosPickerItem]) async {
        isLoadingImages = true

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if !loadedImages.contains(where: { $0.pngData() == image.pngData() }) {
                        loadedImages.append(image)
                    }
                }
            }
        }

        isLoadingImages = false
    }

    private func saveDocument() async {
        guard let type = selectedType else { return }

        // Create document
        let document = await viewModel.createDocument(
            typeId: type.id,
            title: title,
            documentNumber: documentNumber.isEmpty ? nil : documentNumber,
            issueDate: issueDate,
            expirationDate: expirationDate,
            issuingAuthority: issuingAuthority.isEmpty ? nil : issuingAuthority,
            notes: notes.isEmpty ? nil : notes
        )

        // Upload images if any
        if let doc = document, !loadedImages.isEmpty {
            for (index, image) in loadedImages.enumerated() {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    await viewModel.uploadImage(
                        to: doc,
                        imageData: data,
                        fileName: "page_\(index + 1).jpg"
                    )
                }
            }
        }

        if document != nil {
            dismiss()
        }
    }
}

// MARK: - Document Type Card

struct DocumentTypeCard: View {
    let type: DocumentType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.sfSymbol)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.swiftUIColor)

                Text(type.localizedName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.swiftUIColor : NapletColors.backgroundTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.swiftUIColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AddDocumentView(viewModel: DocumentsViewModel(baby: Baby.preview))
}
#endif
