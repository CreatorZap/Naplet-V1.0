import Foundation
import SwiftUI
import PhotosUI

// MARK: - Edit Baby Profile ViewModel
@MainActor
class EditBabyProfileViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: Baby.Gender?
    @Published var photoURL: String?
    @Published var selectedImage: UIImage?
    @Published var imagePickerItem: PhotosPickerItem?

    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showDeleteConfirmation = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Dependencies
    private let supabase = SupabaseService.shared
    private let babyRepository = BabyRepository()

    // MARK: - Baby Reference
    let baby: Baby
    let canEdit: Bool

    // MARK: - Computed Properties

    /// Calcula a idade detalhada do bebê
    var calculatedAge: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate, to: Date())

        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0

        var parts: [String] = []

        if years > 0 {
            parts.append(years == 1 ? "1 \("baby.age.year".localized)" : "\(years) \("baby.age.years".localized)")
        }

        if months > 0 {
            parts.append(months == 1 ? "1 \("baby.age.month".localized)" : "\(months) \("baby.age.months_word".localized)")
        }

        if days > 0 && years == 0 {
            parts.append(days == 1 ? "1 \("baby.age.day".localized)" : "\(days) \("baby.age.days_word".localized)")
        }

        if parts.isEmpty {
            return "baby.age.newborn".localized
        }

        return parts.joined(separator: " \("common.and".localized) ")
    }

    /// Verifica se houve alterações
    var hasChanges: Bool {
        name != baby.name ||
        birthDate != baby.birthDate ||
        gender != baby.gender ||
        selectedImage != nil
    }

    /// Validação do nome
    var isNameValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    /// Validação da data de nascimento
    var isBirthDateValid: Bool {
        birthDate <= Date()
    }

    /// Pode salvar alterações
    var canSave: Bool {
        isNameValid && isBirthDateValid && hasChanges && !isSaving
    }

    // MARK: - Init
    init(baby: Baby) {
        self.baby = baby
        self.name = baby.name
        self.birthDate = baby.birthDate
        self.gender = baby.gender
        self.photoURL = baby.photoURL

        // Verifica se o usuário atual é o dono
        self.canEdit = baby.ownerId == supabase.currentUserId
    }

    // MARK: - Handle Selected Photo
    func handleSelectedPhoto() async {
        guard let item = imagePickerItem else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                errorMessage = "editBaby.error.loadImage".localized
                return
            }

            selectedImage = uiImage
            Logger.info("EditBabyProfileViewModel: Image selected")
        } catch {
            Logger.error("EditBabyProfileViewModel: Failed to load photo - \(error)")
            errorMessage = "editBaby.error.loadImage".localized
        }
    }

    // MARK: - Upload Photo
    private func uploadPhoto() async -> String? {
        guard let image = selectedImage else { return photoURL }

        Logger.info("EditBabyProfileViewModel: Starting photo upload for baby: \(baby.id.uuidString)")

        guard let resizedImage = image.resized(to: CGSize(width: 400, height: 400)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            Logger.error("EditBabyProfileViewModel: Failed to process image")
            return photoURL
        }

        Logger.info("EditBabyProfileViewModel: Image processed, size: \(imageData.count) bytes")

        let fileName = "\(baby.id.uuidString)/photo.jpg"
        Logger.info("EditBabyProfileViewModel: Upload path: \(fileName)")

        do {
            // Remove existing photo if any
            do {
                try await supabase.client.storage
                    .from("baby-photos")
                    .remove(paths: [fileName])
                Logger.info("EditBabyProfileViewModel: Removed existing photo")
            } catch {
                Logger.info("EditBabyProfileViewModel: No existing photo to remove (OK)")
            }

            // Upload new photo
            Logger.info("EditBabyProfileViewModel: Uploading to bucket 'baby-photos'...")
            _ = try await supabase.client.storage
                .from("baby-photos")
                .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))

            Logger.info("EditBabyProfileViewModel: Upload successful!")

            // Get public URL
            let publicURL = try supabase.client.storage
                .from("baby-photos")
                .getPublicURL(path: fileName)

            // Add timestamp to avoid cache
            let photoURLString = "\(publicURL.absoluteString)?t=\(Int(Date().timeIntervalSince1970))"

            Logger.info("EditBabyProfileViewModel: Photo URL: \(photoURLString)")
            return photoURLString
        } catch {
            Logger.error("EditBabyProfileViewModel: ❌ UPLOAD FAILED")
            Logger.error("EditBabyProfileViewModel: Error type: \(type(of: error))")
            Logger.error("EditBabyProfileViewModel: Error: \(error)")
            Logger.error("EditBabyProfileViewModel: Localized: \(error.localizedDescription)")
            errorMessage = "editBaby.error.uploadPhoto".localized
            return photoURL
        }
    }

    // MARK: - Save Changes
    func saveChanges() async -> Bool {
        guard canSave else {
            Logger.warning("EditBabyProfileViewModel: canSave is false - name valid: \(isNameValid), birthDate valid: \(isBirthDateValid), hasChanges: \(hasChanges)")
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        Logger.info("EditBabyProfileViewModel: Starting save...")
        Logger.info("EditBabyProfileViewModel: Baby ID: \(baby.id)")
        Logger.info("EditBabyProfileViewModel: Has selected image: \(selectedImage != nil)")

        do {
            // Upload photo if selected
            let newPhotoURL = await uploadPhoto()
            Logger.info("EditBabyProfileViewModel: Photo URL after upload: \(newPhotoURL ?? "nil")")

            // Check if photo upload failed
            if selectedImage != nil && newPhotoURL == photoURL {
                Logger.error("EditBabyProfileViewModel: Photo upload may have failed, URL unchanged")
                // Se a foto falhou mas temos outras mudanças, continua
            }

            // Create updated baby
            var updatedBaby = baby
            updatedBaby.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedBaby.birthDate = birthDate
            updatedBaby.gender = gender
            updatedBaby.photoURL = newPhotoURL

            Logger.info("EditBabyProfileViewModel: Updating baby in database...")

            // Update in Supabase
            try await babyRepository.updateBaby(updatedBaby)

            Logger.info("EditBabyProfileViewModel: Database update successful!")

            // Update local photoURL
            photoURL = newPhotoURL
            selectedImage = nil

            successMessage = "editBaby.success.saved".localized
            Logger.info("EditBabyProfileViewModel: Baby updated successfully")

            // Clear success message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }

            return true
        } catch {
            Logger.error("EditBabyProfileViewModel: ❌ SAVE FAILED")
            Logger.error("EditBabyProfileViewModel: Error type: \(type(of: error))")
            Logger.error("EditBabyProfileViewModel: Error: \(error)")
            Logger.error("EditBabyProfileViewModel: Localized: \(error.localizedDescription)")
            errorMessage = "editBaby.error.save".localized
            return false
        }
    }

    // MARK: - Delete Baby
    func deleteBaby() async -> Bool {
        guard canEdit else {
            errorMessage = "editBaby.error.notOwner".localized
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            // Delete photo from storage if exists
            if photoURL != nil {
                let fileName = "\(baby.id.uuidString)/photo.jpg"
                do {
                    try await supabase.client.storage
                        .from("baby-photos")
                        .remove(paths: [fileName])
                } catch {
                    Logger.info("EditBabyProfileViewModel: No photo to delete")
                }
            }

            // Delete baby from Supabase
            try await babyRepository.deleteBaby(baby)

            Logger.info("EditBabyProfileViewModel: Baby deleted successfully")
            return true
        } catch {
            Logger.error("EditBabyProfileViewModel: Failed to delete - \(error)")
            errorMessage = "editBaby.error.delete".localized
            return false
        }
    }

    // MARK: - Remove Photo
    func removePhoto() async {
        guard let _ = photoURL else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let fileName = "\(baby.id.uuidString)/photo.jpg"
            try await supabase.client.storage
                .from("baby-photos")
                .remove(paths: [fileName])

            // Update baby in database
            var updatedBaby = baby
            updatedBaby.photoURL = nil
            try await babyRepository.updateBaby(updatedBaby)

            photoURL = nil
            selectedImage = nil

            successMessage = "editBaby.success.photoRemoved".localized
            Logger.info("EditBabyProfileViewModel: Photo removed")

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            Logger.error("EditBabyProfileViewModel: Failed to remove photo - \(error)")
            errorMessage = "editBaby.error.removePhoto".localized
        }
    }
}
