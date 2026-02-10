import SwiftUI

// MARK: - Documents View
struct DocumentsView: View {
    @StateObject private var viewModel: DocumentsViewModel
    @State private var showAddDocument = false
    @State private var selectedDocument: BabyDocument?

    let baby: Baby
    
    init(baby: Baby) {
        self.baby = baby
        _viewModel = StateObject(wrappedValue: DocumentsViewModel(baby: baby))
    }

    var body: some View {
        ZStack {
            NapletColors.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.documents.isEmpty {
                loadingView
            } else if viewModel.documents.isEmpty {
                emptyState
            } else {
                documentsList
            }
        }
        .navigationTitle("documents.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddDocument = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(NapletColors.primaryPurple)
                        .font(.title2)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "documents.search".localized)
        .toolbarBackground(NapletColors.background, for: .navigationBar)
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showAddDocument) {
            AddDocumentView(viewModel: viewModel)
                .presentationBackground(NapletColors.background)
        }
        .sheet(item: $selectedDocument) { document in
            DocumentDetailView(viewModel: viewModel, document: document)
                .presentationBackground(NapletColors.background)
        }
        .alert("common.error".localized, isPresented: $viewModel.showError) {
            Button("common.ok".localized, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
            Text("documents.loading".localized)
                .font(.subheadline)
                .foregroundColor(NapletColors.textSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 64))
                .foregroundColor(NapletColors.textSecondary.opacity(0.5))

            Text("documents.empty.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(NapletColors.textPrimary)

            Text("documents.empty.subtitle".localized)
                .font(.subheadline)
                .foregroundColor(NapletColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showAddDocument = true }) {
                Label("documents.add.first".localized, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(NapletColors.primaryPurple)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Documents List

    private var documentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Expiring Alert
                if viewModel.expiringDocumentsCount > 0 {
                    expiringAlert
                }

                // Filters
                filtersSection

                // Documents Grid
                ForEach(viewModel.filteredDocuments) { document in
                    DocumentCard(document: document)
                        .onTapGesture {
                            selectedDocument = document
                        }
                        .contextMenu {
                            Button(action: {
                                Task { await viewModel.toggleFavorite(document) }
                            }) {
                                Label(
                                    document.isFavorite ? "documents.unfavorite".localized : "documents.favorite".localized,
                                    systemImage: document.isFavorite ? "star.slash" : "star.fill"
                                )
                            }

                            Button(role: .destructive, action: {
                                Task { await viewModel.deleteDocument(document) }
                            }) {
                                Label("common.delete".localized, systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Expiring Alert

    private var expiringAlert: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(NapletColors.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text("documents.expiring.alert".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(NapletColors.textPrimary)

                Text(String(format: "documents.expiring.count".localized, viewModel.expiringDocumentsCount))
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)
            }

            Spacer()

            Button(action: { viewModel.showOnlyExpiring.toggle() }) {
                Text("documents.view".localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(NapletColors.primaryPurple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NapletColors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(NapletColors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                DocumentFilterChip(
                    title: "documents.filter.all".localized,
                    isSelected: viewModel.selectedTypeFilter == nil && !viewModel.showOnlyFavorites && !viewModel.showOnlyExpiring,
                    action: { viewModel.clearFilters() }
                )

                DocumentFilterChip(
                    title: "documents.filter.favorites".localized,
                    icon: "star.fill",
                    isSelected: viewModel.showOnlyFavorites,
                    action: {
                        viewModel.showOnlyFavorites.toggle()
                        viewModel.showOnlyExpiring = false
                    }
                )

                ForEach(viewModel.documentTypes.prefix(6)) { type in
                    DocumentFilterChip(
                        title: type.localizedName,
                        icon: type.sfSymbol,
                        isSelected: viewModel.selectedTypeFilter?.id == type.id,
                        action: { viewModel.selectTypeFilter(type) }
                    )
                }
            }
        }
    }
}

// MARK: - Document Filter Chip

struct DocumentFilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? NapletColors.primaryPurple : NapletColors.cardBackground)
            )
        }
    }
}

// MARK: - Document Card

struct DocumentCard: View {
    let document: BabyDocument

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail or icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(document.documentType?.swiftUIColor.opacity(0.15) ?? NapletColors.primaryPurple.opacity(0.15))
                    .frame(width: 60, height: 60)

                if let thumbnailURL = document.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            Image(systemName: document.documentType?.sfSymbol ?? "doc.fill")
                                .font(.title2)
                                .foregroundColor(document.documentType?.swiftUIColor ?? NapletColors.primaryPurple)
                        case .empty:
                            ProgressView()
                                .tint(NapletColors.primaryPurple)
                        @unknown default:
                            Image(systemName: document.documentType?.sfSymbol ?? "doc.fill")
                                .font(.title2)
                                .foregroundColor(document.documentType?.swiftUIColor ?? NapletColors.primaryPurple)
                        }
                    }
                } else {
                    Image(systemName: document.documentType?.sfSymbol ?? "doc.fill")
                        .font(.title2)
                        .foregroundColor(document.documentType?.swiftUIColor ?? NapletColors.primaryPurple)
                }

                // Favorite badge
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Circle().fill(NapletColors.cardBackground))
                        .offset(x: 24, y: -24)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(1)

                Text(document.documentType?.localizedName ?? "")
                    .font(.caption)
                    .foregroundColor(NapletColors.textSecondary)

                if let number = document.documentNumber, !number.isEmpty {
                    Text(number)
                        .font(.caption)
                        .foregroundColor(NapletColors.textSecondary)
                }

                // Expiration status
                if document.expirationStatus != .noExpiration {
                    HStack(spacing: 4) {
                        Image(systemName: document.expirationStatus.icon)
                            .font(.caption2)

                        Text(expirationText)
                            .font(.caption2)
                    }
                    .foregroundColor(document.expirationStatus.color)
                }
            }

            Spacer()

            // File count
            if document.fileCount > 0 {
                VStack {
                    Text("\(document.fileCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(NapletColors.textSecondary)

                    Image(systemName: "doc.fill")
                        .font(.caption2)
                        .foregroundColor(NapletColors.textSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(NapletColors.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NapletColors.cardBackground)
        )
    }

    private var expirationText: String {
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
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        DocumentsView(baby: Baby.preview)
    }
}
#endif
