import Foundation
import Combine

// MARK: - Notification Extension
extension Notification.Name {
    static let caregiverAccepted = Notification.Name("caregiverAccepted")
}

// MARK: - Caregiver View Model
@MainActor
class CaregiverViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var caregivers: [Caregiver] = []
    @Published var pendingInvites: [Invite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Invite Creation
    @Published var showCreateInvite = false
    @Published var selectedRole: Caregiver.CaregiverRole = .parent
    @Published var inviteEmail = ""
    @Published var createdInvite: Invite?
    @Published var showShareSheet = false

    // Accept Invite
    @Published var inviteCode = ""
    @Published var isAcceptingInvite = false
    @Published var acceptedSuccessfully = false

    // Current User Role
    @Published var currentUserRole: Caregiver.CaregiverRole?

    // MARK: - Dependencies
    private let repository = CaregiverRepository()
    private let baby: Baby

    // MARK: - Computed Properties
    var canInvite: Bool {
        currentUserRole?.canInvite ?? false
    }

    var canRemoveCaregivers: Bool {
        currentUserRole?.canRemoveCaregivers ?? false
    }

    var activeCaregivers: [Caregiver] {
        caregivers.filter { $0.isAccepted }
    }

    var pendingCaregivers: [Caregiver] {
        caregivers.filter { $0.isPending }
    }

    var shareMessage: String {
        guard let invite = createdInvite else { return "" }
        return """
        Olá! Você foi convidado para acompanhar o sono de \(baby.name) no Naplet.

        Use o código: \(invite.inviteCode)

        Baixe o app e use este código para aceitar o convite.
        """
    }

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch caregivers
            caregivers = try await repository.fetchCaregivers(for: baby.id)

            // Fetch pending invites
            pendingInvites = try await repository.fetchPendingInvites(for: baby.id)

            // Get current user role
            currentUserRole = try await repository.getUserRole(for: baby.id)

            Logger.info("Loaded \(caregivers.count) caregivers and \(pendingInvites.count) pending invites")
        } catch {
            Logger.error("Failed to load caregivers: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Create Invite
    func createInvite() async {
        isLoading = true
        errorMessage = nil

        do {
            let email = inviteEmail.isEmpty ? nil : inviteEmail
            createdInvite = try await repository.createInvite(
                for: baby.id,
                email: email,
                role: selectedRole,
                expiresInDays: 7
            )

            // Reload pending invites
            pendingInvites = try await repository.fetchPendingInvites(for: baby.id)

            // Show share sheet
            showShareSheet = true

            Logger.info("Invite created: \(createdInvite?.inviteCode ?? "unknown")")
        } catch {
            Logger.error("Failed to create invite: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Accept Invite
    func acceptInvite() async {
        guard !inviteCode.isEmpty else {
            errorMessage = "invite.error.enterCode".localized
            showError = true
            return
        }

        isAcceptingInvite = true
        errorMessage = nil

        do {
            // Try RPC first, fallback to manual
            let response = try await repository.acceptInvite(code: inviteCode.uppercased())

            if response.success {
                acceptedSuccessfully = true

                // Post notification to update other views
                NotificationCenter.default.post(name: .caregiverAccepted, object: nil)

                Logger.info("Invite accepted successfully")
            } else {
                errorMessage = response.error ?? "Falha ao aceitar convite"
                showError = true
            }
        } catch is CaregiverRepositoryError {
            // Try manual method as fallback
            do {
                _ = try await repository.acceptInviteManual(code: inviteCode.uppercased())
                acceptedSuccessfully = true
                NotificationCenter.default.post(name: .caregiverAccepted, object: nil)
            } catch {
                Logger.error("Failed to accept invite: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            Logger.error("Failed to accept invite: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isAcceptingInvite = false
    }

    // MARK: - Remove Caregiver
    func removeCaregiver(_ caregiver: Caregiver) async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.removeCaregiver(caregiver)
            caregivers.removeAll { $0.id == caregiver.id }
            Logger.info("Caregiver removed")
        } catch {
            Logger.error("Failed to remove caregiver: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Update Role
    func updateRole(for caregiver: Caregiver, to newRole: Caregiver.CaregiverRole) async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.updateCaregiverRole(caregiver, newRole: newRole)

            // Update local state
            if let index = caregivers.firstIndex(where: { $0.id == caregiver.id }) {
                caregivers[index].role = newRole
            }

            Logger.info("Caregiver role updated to \(newRole.displayName)")
        } catch {
            Logger.error("Failed to update role: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Cancel Invite
    func cancelInvite(_ invite: Invite) async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.cancelInvite(invite)
            pendingInvites.removeAll { $0.id == invite.id }
            Logger.info("Invite cancelled")
        } catch {
            Logger.error("Failed to cancel invite: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Reset Invite Form
    func resetInviteForm() {
        selectedRole = .parent
        inviteEmail = ""
        createdInvite = nil
    }
}
