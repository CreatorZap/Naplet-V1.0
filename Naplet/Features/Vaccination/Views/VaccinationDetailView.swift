import SwiftUI

// MARK: - Vaccination Detail View
struct VaccinationDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let vaccination: VaccinationWithDetails
    let baby: Baby
    let onComplete: (Date, String?, String?, String?) -> Void  // date, batch, location, notes
    let onMarkPending: () -> Void

    // Form State
    @State private var applicationDate = Date()
    @State private var batchNumber = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var showConfirmation = false
    @State private var isSubmitting = false

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
                            // Header
                            headerSection

                            // Vaccine Info
                            vaccineInfoSection

                            // Status Section
                            if vaccination.vaccination.status == .completed {
                                completedInfoSection
                            } else {
                                // Application Form
                                applicationFormSection
                            }

                            // Diseases Prevented
                            diseasesSection

                            // Action Button
                            actionButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .transition(.opacity)
                } else {
                    ProgressView()
                        .tint(NapletColors.primaryCyan)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isReady)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isReady = true
                }
            }
            .navigationTitle("vaccination.detail.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.textSecondary)
                }
            }
            .alert("vaccination.markPending.confirm".localized, isPresented: $showConfirmation) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("vaccination.markPending.action".localized, role: .destructive) {
                    onMarkPending()
                }
            } message: {
                Text("vaccination.markPending.message".localized)
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 18) {
            // Status Badge - Refined with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [statusColor.opacity(0.2), statusColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                Image(systemName: "syringe.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(statusColor)
            }

            VStack(spacing: 6) {
                Text(vaccination.vaccine.localizedName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(NapletColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let desc = vaccination.vaccine.localizedDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(NapletColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }

            // Status Pill - More subtle
            HStack(spacing: 6) {
                Image(systemName: vaccination.vaccination.status.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(vaccination.vaccination.status.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.12))
            .cornerRadius(20)
        }
    }

    private var statusColor: Color {
        if vaccination.vaccination.status == .completed {
            return NapletColors.success
        } else if vaccination.isOverdue(babyBirthDate: baby.birthDate) {
            return NapletColors.error
        }
        return NapletColors.primaryBlue
    }

    // MARK: - Vaccine Info Section
    private var vaccineInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("vaccination.info.title".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NapletColors.textPrimary)

            VStack(spacing: 14) {
                infoRow(
                    icon: "calendar",
                    label: "vaccination.info.recommendedAge".localized,
                    value: vaccination.vaccine.recommendedAgeText
                )

                infoRow(
                    icon: "number.circle",
                    label: "vaccination.info.dose".localized,
                    value: vaccination.vaccine.doseText
                )

                infoRow(
                    icon: "tag.fill",
                    label: "vaccination.info.category".localized,
                    value: vaccination.vaccine.category.displayName,
                    valueColor: vaccination.vaccine.category.color
                )

                if vaccination.vaccine.isRequired {
                    infoRow(
                        icon: "checkmark.shield.fill",
                        label: "vaccination.info.required".localized,
                        value: "vaccination.info.yes".localized,
                        valueColor: NapletColors.success
                    )
                }
            }
            .padding(18)
            .background(NapletColors.cardBackground)
            .cornerRadius(16)
        }
    }

    private func infoRow(icon: String, label: String, value: String, valueColor: Color = NapletColors.textPrimary) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(NapletColors.primaryCyan)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(NapletColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }

    // MARK: - Completed Info Section
    private var completedInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("vaccination.completed.title".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            VStack(spacing: 12) {
                if let date = vaccination.vaccination.applicationDate {
                    infoRow(
                        icon: "calendar.badge.checkmark",
                        label: "vaccination.completed.date".localized,
                        value: formatDate(date),
                        valueColor: NapletColors.success
                    )
                }

                if let batch = vaccination.vaccination.batchNumber, !batch.isEmpty {
                    infoRow(
                        icon: "barcode",
                        label: "vaccination.completed.batch".localized,
                        value: batch
                    )
                }

                if let location = vaccination.vaccination.location, !location.isEmpty {
                    infoRow(
                        icon: "mappin",
                        label: "vaccination.completed.location".localized,
                        value: location
                    )
                }

                if let notes = vaccination.vaccination.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(NapletColors.primaryCyan)
                                .frame(width: 24)
                            Text("vaccination.completed.notes".localized)
                                .foregroundColor(NapletColors.textSecondary)
                            Spacer()
                        }
                        .font(.subheadline)

                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(NapletColors.textPrimary)
                            .padding(.leading, 32)
                    }
                }

            }
            .padding(16)
            .background(NapletColors.cardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Application Form Section
    private var applicationFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("vaccination.form.title".localized)
                .font(.headline)
                .foregroundColor(NapletColors.textPrimary)

            VStack(spacing: 16) {
                // Application Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("vaccination.form.date".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    DatePicker(
                        "",
                        selection: $applicationDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(NapletColors.primaryCyan)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NapletColors.backgroundTertiary)
                    .cornerRadius(12)
                }

                // Batch Number
                VStack(alignment: .leading, spacing: 8) {
                    Text("vaccination.form.batch".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    TextField("vaccination.form.batchPlaceholder".localized, text: $batchNumber)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                        .foregroundColor(NapletColors.textPrimary)
                }

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("vaccination.form.location".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    TextField("vaccination.form.locationPlaceholder".localized, text: $location)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                        .foregroundColor(NapletColors.textPrimary)
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("vaccination.form.notes".localized)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)

                    TextField("vaccination.form.notesPlaceholder".localized, text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(NapletColors.backgroundTertiary)
                        .cornerRadius(12)
                        .foregroundColor(NapletColors.textPrimary)
                }
            }
            .padding(16)
            .background(NapletColors.cardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Additional Info Section
    private var diseasesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Protection Info
            if let protectionInfo = vaccination.vaccine.protectionInfo, !protectionInfo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(NapletColors.success)
                        Text("vaccination.protection.title".localized)
                            .font(.headline)
                            .foregroundColor(NapletColors.textPrimary)
                    }
                    Text(protectionInfo)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)
                }
            }

            // Side Effects
            if let sideEffects = vaccination.vaccine.sideEffects, !sideEffects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(NapletColors.warning)
                        Text("vaccination.sideEffects.title".localized)
                            .font(.headline)
                            .foregroundColor(NapletColors.textPrimary)
                    }
                    Text(sideEffects)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)
                }
            }

            // Post Vaccine Tips
            if let tips = vaccination.vaccine.postVaccineTips, !tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(NapletColors.primaryCyan)
                        Text("vaccination.tips.title".localized)
                            .font(.headline)
                            .foregroundColor(NapletColors.textPrimary)
                    }
                    Text(tips)
                        .font(.subheadline)
                        .foregroundColor(NapletColors.textSecondary)
                }
            }
        }
        .padding(16)
        .background(NapletColors.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Action Button
    private var actionButton: some View {
        VStack(spacing: 12) {
            if vaccination.vaccination.status == .completed {
                Button {
                    showConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 15, weight: .semibold))
                        Text("vaccination.action.markPending".localized)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(NapletColors.warning)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(NapletColors.warning.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(NapletColors.warning.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                Button {
                    guard !isSubmitting else { return }
                    isSubmitting = true
                    Logger.info("VaccinationDetailView: Mark Complete button tapped")
                    onComplete(
                        applicationDate,
                        batchNumber.isEmpty ? nil : batchNumber,
                        location.isEmpty ? nil : location,
                        notes.isEmpty ? nil : notes
                    )
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isSubmitting ? "vaccination.action.saving".localized : "vaccination.action.markComplete".localized)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: isSubmitting ? 
                                [NapletColors.success.opacity(0.7), NapletColors.success.opacity(0.5)] :
                                [NapletColors.success, NapletColors.success.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(isSubmitting)
            }
        }
    }

    // MARK: - Helpers
    private func loadExistingData() {
        if let date = vaccination.vaccination.applicationDate {
            applicationDate = date
        }
        batchNumber = vaccination.vaccination.batchNumber ?? ""
        location = vaccination.vaccination.location ?? ""
        notes = vaccination.vaccination.notes ?? ""
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VaccinationDetailView(
        vaccination: VaccinationWithDetails(
            id: UUID(),
            vaccination: BabyVaccination(
                babyId: UUID(),
                vaccineId: UUID(),
                status: .pending
            ),
            vaccine: Vaccine(
                id: UUID(),
                name: "BCG",
                nameEn: "BCG",
                description: "Protege contra formas graves de tuberculose",
                descriptionEn: "Protects against severe forms of tuberculosis",
                ageMonths: 0,
                doseNumber: 1,
                totalDoses: 1,
                isRequired: true,
                isPrivate: false,
                protectionInfo: "Tuberculose, Meningite tuberculosa",
                sideEffects: "Pode causar vermelhidão no local da aplicação",
                postVaccineTips: "Mantenha o local limpo e seco",
                createdAt: Date()
            )
        ),
        baby: Baby.preview,
        onComplete: { _, _, _, _ in },
        onMarkPending: {}
    )
}
#endif
