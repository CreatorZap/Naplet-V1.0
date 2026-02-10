import SwiftUI
import PhotosUI

// MARK: - Profile View
/// Tela de edição do perfil do usuário
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showRemoveAvatarAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: NapletSpacing.xl) {
                        // Avatar Section
                        avatarSection
                        
                        // Name Section
                        nameSection
                        
                        // Account Info Section
                        accountInfoSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(NapletSpacing.lg)
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .background(NapletColors.background)
            .navigationTitle("profile.title".localized)
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
            .alert("profile.removeAvatar.title".localized, isPresented: $showRemoveAvatarAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.remove".localized, role: .destructive) {
                    Task {
                        await viewModel.removeAvatar()
                    }
                }
            } message: {
                Text("profile.removeAvatar.message".localized)
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
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        let selectedImage = viewModel.selectedImage
        let profileAvatarUrl = viewModel.profile?.avatarUrl
        let profileDisplayName = viewModel.profile?.displayName

        return VStack(spacing: NapletSpacing.md) {
            // Avatar with photo picker
            PhotosPicker(selection: $viewModel.imagePickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(NapletColors.gradientPrimary, lineWidth: 3)
                            )
                    } else {
                        AvatarView(
                            imageURL: profileAvatarUrl,
                            name: profileDisplayName,
                            size: .profile,
                            showBorder: true
                        )
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
                    Text("profile.changePhoto".localized)
                        .font(NapletTypography.callout())
                        .foregroundColor(NapletColors.primaryPurple)
                }
                .disabled(viewModel.isSaving)
                
                if viewModel.profile?.avatarUrl != nil || viewModel.selectedImage != nil {
                    Text("•")
                        .foregroundColor(NapletColors.textMuted)
                    
                    Button("profile.removePhoto".localized) {
                        showRemoveAvatarAlert = true
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
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text("profile.displayName".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
            
            HStack(spacing: NapletSpacing.sm) {
                TextField("profile.displayName.placeholder".localized, text: $viewModel.displayName)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textPrimary)
                    .padding(NapletSpacing.md)
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(12)
                    .disabled(viewModel.isSaving)
                
                Button {
                    Task {
                        await viewModel.updateDisplayName()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 44, height: 44)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .background(NapletColors.primaryPurple)
                .cornerRadius(12)
                .disabled(viewModel.isSaving || viewModel.displayName.isEmpty)
            }
        }
        .padding(NapletSpacing.lg)
        .background(NapletColors.backgroundTertiary)
        .cornerRadius(16)
    }
    
    // MARK: - Account Info Section
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.md) {
            Text("profile.accountInfo".localized)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textMuted)
            
            VStack(spacing: 0) {
                // Email
                infoRow(
                    icon: "envelope.fill",
                    label: "profile.email".localized,
                    value: viewModel.profile?.email ?? "-"
                )
                
                Divider()
                    .background(NapletColors.textMuted.opacity(0.2))
                
                // Subscription (usa SubscriptionManager que verifica desenvolvedor)
                infoRow(
                    icon: "crown.fill",
                    label: "profile.subscription".localized,
                    value: subscriptionStatusDisplayName,
                    valueColor: subscriptionManager.isPremium ? NapletColors.warning : nil
                )
                
                Divider()
                    .background(NapletColors.textMuted.opacity(0.2))
                
                // Member since
                infoRow(
                    icon: "calendar",
                    label: "profile.memberSince".localized,
                    value: viewModel.profile?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "-"
                )
            }
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(12)
        }
        .padding(NapletSpacing.lg)
        .background(NapletColors.backgroundTertiary)
        .cornerRadius(16)
    }
    
    // MARK: - Info Row
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color? = nil
    ) -> some View {
        HStack(spacing: NapletSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(NapletColors.primaryPurple)
                .frame(width: 24)
            
            Text(label)
                .font(NapletTypography.body())
                .foregroundColor(NapletColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(NapletTypography.body())
                .foregroundColor(valueColor ?? NapletColors.textPrimary)
        }
        .padding(NapletSpacing.md)
    }
    
    // MARK: - Subscription Status
    /// Retorna o nome do status da assinatura, priorizando SubscriptionManager (que verifica desenvolvedor)
    private var subscriptionStatusDisplayName: String {
        if subscriptionManager.isPremium {
            return "subscription.tier.premium".localized
        } else if subscriptionManager.isTrial {
            return "subscription.tier.trial".localized
        } else {
            return "subscription.tier.free".localized
        }
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
    ProfileView()
}
