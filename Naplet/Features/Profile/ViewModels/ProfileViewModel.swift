import Foundation
import SwiftUI
import PhotosUI

// MARK: - Profile ViewModel
@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var profile: Profile?
    @Published var displayName: String = ""
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showImagePicker = false
    @Published var imagePickerItem: PhotosPickerItem?
    
    // MARK: - Dependencies
    private let supabase = SupabaseService.shared
    
    // MARK: - Init
    init() {
        Task {
            await loadProfile()
        }
    }
    
    // MARK: - Load Profile
    func loadProfile() async {
        guard let userId = supabase.currentUser?.id else {
            Logger.error("ProfileViewModel: No authenticated user")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedProfile: Profile = try await supabase.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            self.profile = fetchedProfile
            self.displayName = fetchedProfile.displayName ?? ""
            
            Logger.info("ProfileViewModel: Profile loaded - \(fetchedProfile.displayName ?? "no name")")
        } catch {
            Logger.error("ProfileViewModel: Failed to load profile - \(error)")
            errorMessage = "profile.error.load".localized
        }
    }
    
    // MARK: - Update Display Name
    func updateDisplayName() async {
        guard let userId = supabase.currentUser?.id else { return }
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "profile.error.emptyName".localized
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            let update = ProfileUpdate(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            try await supabase.client
                .from("profiles")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Atualiza o profile local
            profile?.displayName = displayName
            
            successMessage = "profile.success.nameSaved".localized
            Logger.info("ProfileViewModel: Display name updated")
            
            // Limpa mensagem após 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            Logger.error("ProfileViewModel: Failed to update name - \(error)")
            errorMessage = "profile.error.saveName".localized
        }
    }
    
    // MARK: - Handle Selected Photo
    func handleSelectedPhoto() async {
        guard let item = imagePickerItem else { return }
        
        do {
            // Carrega os dados da imagem
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                errorMessage = "profile.error.loadImage".localized
                return
            }
            
            selectedImage = uiImage
            
            // Faz upload da imagem
            await uploadAvatar(image: uiImage)
        } catch {
            Logger.error("ProfileViewModel: Failed to load photo - \(error)")
            errorMessage = "profile.error.loadImage".localized
        }
    }
    
    // MARK: - Upload Avatar
    func uploadAvatar(image: UIImage) async {
        guard let userId = supabase.currentUser?.id else {
            Logger.error("ProfileViewModel: No user ID for upload")
            errorMessage = "profile.error.uploadAvatar".localized
            return
        }
        
        Logger.info("ProfileViewModel: Starting avatar upload for user \(userId.uuidString)")
        
        // Redimensiona e comprime a imagem
        guard let resizedImage = image.resized(to: CGSize(width: 400, height: 400)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            Logger.error("ProfileViewModel: Failed to resize/compress image")
            errorMessage = "profile.error.processImage".localized
            return
        }
        
        Logger.info("ProfileViewModel: Image prepared - size: \(imageData.count) bytes")
        
        isSaving = true
        defer { isSaving = false }
        
        let fileName = "\(userId.uuidString)/avatar.jpg"
        Logger.info("ProfileViewModel: Uploading to path: \(fileName)")
        
        do {
            // Primeiro tenta remover arquivo existente (ignora erro se não existir)
            do {
                try await supabase.client.storage
                    .from("avatars")
                    .remove(paths: [fileName])
                Logger.info("ProfileViewModel: Removed existing avatar")
            } catch {
                Logger.info("ProfileViewModel: No existing avatar to remove (this is OK)")
            }
            
            // Upload para Supabase Storage
            _ = try await supabase.client.storage
                .from("avatars")
                .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))
            
            Logger.info("ProfileViewModel: Upload successful")
            
            // Obtém URL pública
            let publicURL = try supabase.client.storage
                .from("avatars")
                .getPublicURL(path: fileName)
            
            Logger.info("ProfileViewModel: Public URL: \(publicURL.absoluteString)")
            
            // Adiciona timestamp para evitar cache
            let avatarURL = "\(publicURL.absoluteString)?t=\(Int(Date().timeIntervalSince1970))"
            
            // Atualiza o perfil com a nova URL
            let update = ProfileUpdate(avatarUrl: avatarURL)
            
            try await supabase.client
                .from("profiles")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
            
            Logger.info("ProfileViewModel: Profile updated with avatar URL")
            
            // Atualiza localmente
            profile?.avatarUrl = avatarURL
            
            successMessage = "profile.success.avatarSaved".localized
            Logger.info("ProfileViewModel: Avatar uploaded successfully")
            
            // Limpa mensagem após 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            // Log detalhado do erro
            Logger.error("ProfileViewModel: Upload failed - \(error)")
            Logger.error("ProfileViewModel: Full error: \(String(describing: error))")
            errorMessage = "profile.error.uploadAvatar".localized
        }
    }
    
    // MARK: - Remove Avatar
    func removeAvatar() async {
        guard let userId = supabase.currentUser?.id else { return }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Remove do Storage
            let fileName = "\(userId.uuidString)/avatar.jpg"
            try await supabase.client.storage
                .from("avatars")
                .remove(paths: [fileName])
            
            // Atualiza o perfil
            let update = ProfileUpdate(avatarUrl: nil)
            
            try await supabase.client
                .from("profiles")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Atualiza localmente
            profile?.avatarUrl = nil
            selectedImage = nil
            
            successMessage = "profile.success.avatarRemoved".localized
            Logger.info("ProfileViewModel: Avatar removed")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            Logger.error("ProfileViewModel: Failed to remove avatar - \(error)")
            errorMessage = "profile.error.removeAvatar".localized
        }
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - UIImage Extension
extension UIImage {
    /// Redimensiona a imagem mantendo a proporção
    func resized(to targetSize: CGSize) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - ProfileUpdate Extension
extension ProfileUpdate {
    init(displayName: String) {
        self.displayName = displayName
        self.avatarUrl = nil
        self.timezone = nil
        self.locale = nil
        self.notificationToken = nil
    }
    
    init(avatarUrl: String?) {
        self.displayName = nil
        self.avatarUrl = avatarUrl
        self.timezone = nil
        self.locale = nil
        self.notificationToken = nil
    }
}
