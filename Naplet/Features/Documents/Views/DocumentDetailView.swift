import SwiftUI
import PhotosUI

// MARK: - Document Detail View
struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DocumentsViewModel

    let documentId: UUID
    
    // Get the current document from viewModel (so it updates when files are added)
    private var document: BabyDocument? {
        viewModel.documents.first { $0.id == documentId }
    }
    
    // Convenience init for backward compatibility
    init(viewModel: DocumentsViewModel, document: BabyDocument) {
        self.viewModel = viewModel
        self.documentId = document.id
    }

    // Edit Mode
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedNumber: String = ""
    @State private var editedAuthority: String = ""
    @State private var editedNotes: String = ""
    @State private var editedIssueDate: Date?
    @State private var editedExpirationDate: Date?

    // Image Viewer
    @State private var selectedImageIndex: Int?
    @State private var showImageViewer = false

    // Image Picker
    @State private var selectedImages: [PhotosPickerItem] = []

    // Delete Confirmation
    @State private var showDeleteConfirmation = false

    // State to force re-render on appear
    @State private var isReady = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ensure background is always visible
                NapletColors.background
                    .ignoresSafeArea()

                if isReady, let document = document {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            headerSection(for: document)

                            // Document Info
                            documentInfoSection(for: document)

                            // Images
                            imagesSection(for: document)

                            // Notes
                            if let notes = document.notes, !notes.isEmpty {
                                notesSection(notes: notes)
                            }

                            // Actions
                            actionsSection(for: document)
                        }
                        .padding()
                    }
                    .transition(.opacity)
                } else {
                    VStack {
                        ProgressView()
                            .tint(NapletColors.primaryPurple)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isReady)
            .onAppear {
                // Small delay to ensure sheet is fully presented before showing content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isReady = true
                }
            }
            .navigationTitle(document?.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }

                if let document = document {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                startEditing(document: document)
                            } label: {
                                Label("common.edit".localized, systemImage: "pencil")
                            }

                            Button {
                                Task { await viewModel.toggleFavorite(document) }
                            } label: {
                                Label(
                                    document.isFavorite ? "documents.unfavorite".localized : "documents.favorite".localized,
                                    systemImage: document.isFavorite ? "star.slash" : "star.fill"
                                )
                            }

                            Divider()

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("common.delete".localized, systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(NapletColors.primaryPurple)
                        }
                    }
                }
            }
            .toolbarBackground(NapletColors.background, for: .navigationBar)
            .sheet(isPresented: $isEditing) {
                if let document = document {
                    editSheet(for: document)
                }
            }
            .fullScreenCover(isPresented: $showImageViewer) {
                if let index = selectedImageIndex,
                   let files = document?.files,
                   index < files.count {
                    ImageViewerView(
                        files: files,
                        selectedIndex: index
                    )
                }
            }
            .confirmationDialog(
                "documents.delete.confirm".localized,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("common.delete".localized, role: .destructive) {
                    Task {
                        if let document = document {
                            await viewModel.deleteDocument(document)
                        }
                        dismiss()
                    }
                }
            } message: {
                Text("documents.delete.message".localized)
            }
            .onChange(of: selectedImages) { _, newItems in
                Task { 
                    if let document = document {
                        await uploadImages(from: newItems, to: document)
                    }
                }
            }
        }
        .presentationBackground(NapletColors.background)
    }

    // MARK: - Header Section

    private func headerSection(for document: BabyDocument) -> some View {
        VStack(spacing: 16) {
            // Icon and Type
            ZStack {
                Circle()
                    .fill(document.documentType?.swiftUIColor.opacity(0.2) ?? NapletColors.primaryPurple.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: document.documentType?.sfSymbol ?? "doc.fill")
                    .font(.system(size: 32))
                    .foregroundColor(document.documentType?.swiftUIColor ?? NapletColors.primaryPurple)
            }

            VStack(spacing: 4) {
                HStack {
                    Text(document.documentType?.localizedName ?? "")
                        .font(.headline)
                        .foregroundColor(document.documentType?.swiftUIColor ?? NapletColors.primaryPurple)

                    if document.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }

                // Expiration Status
                if document.expirationStatus != .noExpiration {
                    HStack(spacing: 4) {
                        Image(systemName: document.expirationStatus.icon)
                        Text(expirationText(for: document))
                    }
                    .font(.caption)
                    .foregroundColor(document.expirationStatus.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(document.expirationStatus.color.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Document Info Section

    private func documentInfoSection(for document: BabyDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("documents.info".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            VStack(spacing: 12) {
                if let number = document.documentNumber, !number.isEmpty {
                    infoRow(icon: "number", label: "documents.form.number".localized, value: number)
                }

                if let authority = document.issuingAuthority, !authority.isEmpty {
                    infoRow(icon: "building.2", label: "documents.form.authority".localized, value: authority)
                }

                if let issueDate = document.issueDate {
                    infoRow(
                        icon: "calendar",
                        label: "documents.form.issueDate".localized,
                        value: issueDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }

                if let expirationDate = document.expirationDate {
                    infoRow(
                        icon: "calendar.badge.exclamationmark",
                        label: "documents.form.expirationDate".localized,
                        value: expirationDate.formatted(date: .abbreviated, time: .omitted),
                        valueColor: document.expirationStatus.color
                    )
                }

                if let createdAt = document.createdAt {
                    infoRow(
                        icon: "clock",
                        label: "documents.addedOn".localized,
                        value: createdAt.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    private func infoRow(icon: String, label: String, value: String, valueColor: Color = NapletColors.textPrimary) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(NapletColors.primaryPurple)
                .frame(width: 24)

            Text(label)
                .foregroundColor(NapletColors.textSecondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
        .font(.subheadline)
    }

    // MARK: - Images Section

    private func imagesSection(for document: BabyDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("documents.photos".localized)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)
                
                if let files = document.files, !files.isEmpty {
                    Text("(\(files.count))")
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)
                }

                Spacer()

                PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                    Label("documents.addPhoto".localized, systemImage: "plus")
                        .font(.caption)
                        .foregroundColor(NapletColors.primaryPurple)
                }
            }

            if let files = document.files, !files.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                        ZStack(alignment: .topTrailing) {
                            if let url = file.fileURL {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    case .failure:
                                        failedImagePlaceholder
                                    case .empty:
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(NapletColors.backgroundTertiary)
                                                .frame(width: 100, height: 100)
                                            ProgressView()
                                                .tint(NapletColors.primaryPurple)
                                        }
                                    @unknown default:
                                        placeholderImage
                                    }
                                }
                                .onTapGesture {
                                    selectedImageIndex = index
                                    showImageViewer = true
                                }
                            } else {
                                placeholderImage
                            }

                            // Delete button
                            Button {
                                Task {
                                    await viewModel.deleteFile(file, from: document)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundColor(NapletColors.textMuted)

                    Text("documents.noPhotos".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }

            if viewModel.isUploading {
                HStack {
                    ProgressView()
                        .tint(NapletColors.primaryPurple)
                    Text("documents.uploading".localized)
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
    }
    
    private var failedImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(NapletColors.error.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(NapletColors.error)
            )
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(NapletColors.backgroundTertiary)
            .frame(height: 100)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(NapletColors.textMuted)
            )
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("documents.notes".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            Text(notes)
                .font(.subheadline)
                .foregroundColor(NapletColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    // MARK: - Actions Section

    private func actionsSection(for document: BabyDocument) -> some View {
        VStack(spacing: 12) {
            // Share Button
            if let files = document.files, !files.isEmpty {
                ShareLink(items: files.compactMap { $0.fileURL }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("documents.share".localized)
                    }
                    .font(.headline)
                    .foregroundColor(NapletColors.primaryPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(NapletColors.primaryPurple.opacity(0.2))
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Edit Sheet

    private func editSheet(for document: BabyDocument) -> some View {
        NavigationStack {
            ZStack {
                NapletColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("documents.form.title".localized)
                                .font(.subheadline)
                                .foregroundColor(NapletColors.textSecondary)

                            TextField("", text: $editedTitle)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(NapletColors.backgroundTertiary)
                                .cornerRadius(12)
                                .foregroundColor(NapletColors.textPrimary)
                        }

                        // Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("documents.form.number".localized)
                                .font(.subheadline)
                                .foregroundColor(NapletColors.textSecondary)

                            TextField("", text: $editedNumber)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(NapletColors.backgroundTertiary)
                                .cornerRadius(12)
                                .foregroundColor(NapletColors.textPrimary)
                        }

                        // Authority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("documents.form.authority".localized)
                                .font(.subheadline)
                                .foregroundColor(NapletColors.textSecondary)

                            TextField("", text: $editedAuthority)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(NapletColors.backgroundTertiary)
                                .cornerRadius(12)
                                .foregroundColor(NapletColors.textPrimary)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("documents.notes".localized)
                                .font(.subheadline)
                                .foregroundColor(NapletColors.textSecondary)

                            TextField("", text: $editedNotes, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(NapletColors.backgroundTertiary)
                                .cornerRadius(12)
                                .foregroundColor(NapletColors.textPrimary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("common.edit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NapletColors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        isEditing = false
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task { await saveChanges(for: document) }
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }
        }
        .presentationBackground(NapletColors.background)
    }

    // MARK: - Helper Methods

    private func expirationText(for document: BabyDocument) -> String {
        switch document.expirationStatus {
        case .expired:
            return "documents.expired".localized
        case .expiringSoon:
            if let days = document.daysUntilExpiration {
                return String(format: "documents.expiresIn".localized, days)
            }
            return "documents.expiringSoon".localized
        default:
            return ""
        }
    }

    private func startEditing(document: BabyDocument) {
        editedTitle = document.title
        editedNumber = document.documentNumber ?? ""
        editedAuthority = document.issuingAuthority ?? ""
        editedNotes = document.notes ?? ""
        editedIssueDate = document.issueDate
        editedExpirationDate = document.expirationDate
        isEditing = true
    }

    private func saveChanges(for document: BabyDocument) async {
        var updatedDocument = document
        updatedDocument.title = editedTitle
        updatedDocument.documentNumber = editedNumber.isEmpty ? nil : editedNumber
        updatedDocument.issuingAuthority = editedAuthority.isEmpty ? nil : editedAuthority
        updatedDocument.notes = editedNotes.isEmpty ? nil : editedNotes
        updatedDocument.issueDate = editedIssueDate
        updatedDocument.expirationDate = editedExpirationDate

        await viewModel.updateDocument(updatedDocument)
        isEditing = false
    }

    private func uploadImages(from items: [PhotosPickerItem], to document: BabyDocument) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await viewModel.uploadImage(to: document, imageData: data)
            }
        }
        selectedImages = []
        
        // Refresh documents to get updated files
        await viewModel.refresh()
    }
}

// MARK: - Image Viewer View

struct ImageViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let files: [DocumentFile]
    @State var selectedIndex: Int
    @State private var isReady = false

    var body: some View {
        ZStack {
            // Ensure black background is always visible
            Color.black
                .ignoresSafeArea()

            if isReady {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                        if let url = file.fileURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure:
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        Text("documents.error.loadFailed".localized)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .transition(.opacity)

                // Close Button
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }

                    Spacer()

                    // Page indicator
                    Text("\(selectedIndex + 1) / \(files.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                        .padding(.bottom)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isReady)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isReady = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    DocumentDetailView(
        viewModel: DocumentsViewModel(baby: Baby.preview),
        document: BabyDocument.preview
    )
}
#endif
