import SwiftUI
import PDFKit

// MARK: - Report View
struct ReportView: View {
    @StateObject private var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss

    init(baby: Baby) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(baby: baby))
    }

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: NapletSpacing.lg) {
                    // Drag Indicator
                    Capsule()
                        .fill(NapletColors.textMuted.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, NapletSpacing.sm)

                    // Header
                    VStack(spacing: NapletSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(NapletColors.primaryPurple.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 36))
                                .foregroundColor(NapletColors.primaryPurple)
                        }

                        Text(L10n.Report.title.localized)
                            .font(NapletTypography.title2())
                            .foregroundColor(NapletColors.textPrimary)
                    }

                    // Period Selector
                    periodSelector

                    // Preview Card
                    previewCard

                    // Generate Button
                    generateButton

                    // PDF Preview (if generated)
                    if viewModel.pdfData != nil {
                        pdfPreviewSection
                    }

                    // Error Message
                    if let error = viewModel.errorMessage {
                        errorView(error)
                    }
                }
                .padding(NapletSpacing.md)
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let data = viewModel.pdfData {
                ShareSheet(items: [data])
            }
        }
        .task {
            await viewModel.generateReport()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(L10n.Report.period.localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)

            NapletCard {
                HStack(spacing: NapletSpacing.sm) {
                    ForEach(TimePeriod.allCases) { period in
                        periodButton(period)
                    }
                }
            }
        }
    }

    private func periodButton(_ period: TimePeriod) -> some View {
        Button {
            withAnimation {
                viewModel.selectedPeriod = period
            }
            Task {
                await viewModel.generateReport()
            }
        } label: {
            Text(period.rawValue)
                .font(NapletTypography.footnote(weight: .medium))
                .foregroundColor(viewModel.selectedPeriod == period ? .white : NapletColors.textPrimary)
                .padding(.horizontal, NapletSpacing.md)
                .padding(.vertical, NapletSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.selectedPeriod == period ? NapletColors.primaryPurple : NapletColors.backgroundSecondary)
                )
        }
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(L10n.Report.summary.localized)
                .font(NapletTypography.caption(weight: .semibold))
                .foregroundColor(NapletColors.textSecondary)
                .textCase(.uppercase)

            NapletCard {
                VStack(spacing: NapletSpacing.md) {
                    HStack {
                        previewStatItem(
                            icon: "moon.fill",
                            title: L10n.Dashboard.Stats.totalSleep.localized,
                            value: viewModel.previewTotalSleep
                        )

                        Spacer()

                        previewStatItem(
                            icon: "chart.bar.fill",
                            title: "history.averagePerDay".localized,
                            value: viewModel.previewAverageSleep
                        )
                    }

                    Divider()

                    HStack {
                        previewStatItem(
                            icon: "bed.double.fill",
                            title: L10n.Dashboard.Stats.naps.localized,
                            value: viewModel.previewTotalNaps
                        )

                        Spacer()

                        previewStatItem(
                            icon: "star.fill",
                            title: "sleepDetail.quality".localized,
                            value: viewModel.previewQuality
                        )
                    }
                }
            }
        }
    }

    private func previewStatItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(NapletColors.primaryPurple)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textSecondary)

                Text(value)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        VStack(spacing: NapletSpacing.sm) {
            NapletButton(
                L10n.Report.generate.localized,
                style: .primary,
                isLoading: viewModel.isGenerating,
                isFullWidth: true
            ) {
                Task {
                    await viewModel.generateReport()
                }
            }

            Text("report.info".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - PDF Preview Section
    private var pdfPreviewSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            HStack {
                Text("report.preview".localized)
                    .font(NapletTypography.caption(weight: .semibold))
                    .foregroundColor(NapletColors.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    viewModel.sharePDF()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.Report.share.localized)
                    }
                    .font(NapletTypography.footnote(weight: .medium))
                    .foregroundColor(NapletColors.primaryPurple)
                }
            }

            if let pdfData = viewModel.pdfData {
                PDFPreviewView(data: pdfData)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
        }
    }

    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        NapletCard {
            HStack(spacing: NapletSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(NapletColors.error)

                Text(message)
                    .font(NapletTypography.footnote())
                    .foregroundColor(NapletColors.error)

                Spacer()
            }
        }
    }
}

// MARK: - PDF Preview View
struct PDFPreviewView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemGray6

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}

// MARK: - Preview
#Preview {
    ReportView(baby: Baby.preview)
}
