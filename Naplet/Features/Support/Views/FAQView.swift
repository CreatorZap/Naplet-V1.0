import SwiftUI

// MARK: - FAQ View
struct FAQView: View {
    @StateObject private var viewModel = FAQViewModel()
    @State private var selectedCategory: FAQCategory? = nil
    @State private var expandedItemId: UUID? = nil
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var filteredItems: [FAQItem] {
        var items = viewModel.faqItems

        // Filtrar por categoria
        if let category = selectedCategory {
            items = items.filter { $0.category == category.rawValue }
        }

        // Filtrar por busca
        if !searchText.isEmpty {
            items = items.filter {
                $0.localizedQuestion.localizedCaseInsensitiveContains(searchText) ||
                $0.localizedAnswer.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(NapletColors.textMuted.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, NapletSpacing.sm)
                .padding(.bottom, NapletSpacing.md)

            // Header
            VStack(spacing: NapletSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(NapletColors.info.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(NapletColors.info)
                }

                Text("support.faq.title".localized)
                    .font(NapletTypography.title3())
                    .foregroundColor(NapletColors.textPrimary)
            }
            .padding(.bottom, NapletSpacing.md)

            // Barra de busca
            searchBar
                .padding(.horizontal, NapletSpacing.md)
                .padding(.bottom, NapletSpacing.md)

            // Filtros de categoria
            categoryFilters
                .padding(.bottom, NapletSpacing.md)

            // Lista de FAQ
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NapletColors.primaryPurple))
                Spacer()
            } else if filteredItems.isEmpty {
                emptyState
            } else {
                faqList
            }
        }
        .background(NapletColors.background)
        .onAppear {
            viewModel.loadFAQ()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(NapletColors.textSecondary)

            TextField("support.faq.search".localized, text: $searchText)
                .foregroundColor(NapletColors.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(NapletColors.textSecondary)
                }
            }
        }
        .padding(NapletSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(NapletColors.backgroundSecondary)
        )
    }

    // MARK: - Category Filters
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NapletSpacing.xs) {
                // Botao "Todos"
                CategoryFilterButton(
                    title: "support.faq.all".localized,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation { selectedCategory = nil }
                }

                // Categorias
                ForEach(FAQCategory.allCases) { category in
                    CategoryFilterButton(
                        title: category.localizedName,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation { selectedCategory = category }
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.md)
        }
    }

    // MARK: - FAQ List
    private var faqList: some View {
        ScrollView {
            LazyVStack(spacing: NapletSpacing.sm) {
                ForEach(filteredItems) { item in
                    FAQAccordionItem(
                        item: item,
                        isExpanded: expandedItemId == item.id
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedItemId == item.id {
                                expandedItemId = nil
                            } else {
                                expandedItemId = item.id
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            .padding(.horizontal, NapletSpacing.md)
            .padding(.bottom, NapletSpacing.lg)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: NapletSpacing.md) {
            Spacer()

            Image(systemName: "doc.questionmark")
                .font(.system(size: 48))
                .foregroundColor(NapletColors.textSecondary)

            Text("support.faq.noResults".localized)
                .font(NapletTypography.headline())
                .foregroundColor(NapletColors.textSecondary)

            Text("support.faq.tryDifferent".localized)
                .font(NapletTypography.subheadline())
                .foregroundColor(NapletColors.textMuted)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, NapletSpacing.lg)
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NapletTypography.caption())
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : NapletColors.textSecondary)
                .padding(.horizontal, NapletSpacing.sm)
                .padding(.vertical, NapletSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? NapletColors.primaryPurple : NapletColors.backgroundSecondary)
                )
        }
    }
}

// MARK: - FAQ Accordion Item
struct FAQAccordionItem: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header (sempre visivel)
            Button(action: onTap) {
                HStack(spacing: NapletSpacing.sm) {
                    // Icone da categoria
                    if let category = FAQCategory(rawValue: item.category) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14))
                            .foregroundColor(category.color)
                            .frame(width: 24, height: 24)
                    }

                    Text(item.localizedQuestion)
                        .font(NapletTypography.subheadline())
                        .fontWeight(.medium)
                        .foregroundColor(NapletColors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(NapletColors.textSecondary)
                }
                .padding(NapletSpacing.md)
            }

            // Resposta (visivel quando expandido)
            if isExpanded {
                Divider()
                    .background(NapletColors.backgroundSecondary)

                Text(item.localizedAnswer)
                    .font(NapletTypography.subheadline())
                    .foregroundColor(NapletColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .padding(NapletSpacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NapletColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isExpanded ? NapletColors.primaryPurple.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview
#Preview {
    FAQView()
}
