import SwiftUI

// MARK: - Avatar View
/// Componente reutilizável para exibir avatar do usuário ou bebê
/// Carrega imagem de URL com fallback para iniciais ou ícone
struct AvatarView: View {
    let imageURL: String?
    let name: String?
    let size: CGFloat
    var showBorder: Bool = true
    var borderGradient: LinearGradient = NapletColors.gradientPrimary
    var borderWidth: CGFloat = 2
    
    // Computed
    private var initials: String {
        guard let name = name, !name.isEmpty else { return "?" }
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
    
    private var backgroundColor: Color {
        // Gera cor baseada no nome para consistência
        guard let name = name, !name.isEmpty else {
            return NapletColors.backgroundSecondary
        }
        let hash = name.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.4, brightness: 0.7)
    }
    
    var body: some View {
        Group {
            if let urlString = imageURL, 
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                // Imagem de URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .overlay(
                                ProgressView()
                                    .tint(NapletColors.textMuted)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
            } else if name != nil && !name!.isEmpty {
                // Iniciais do nome
                initialsView
            } else {
                // Ícone padrão
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(borderGradient, lineWidth: showBorder ? borderWidth : 0)
        )
    }
    
    // MARK: - Subviews
    
    private var initialsView: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(NapletColors.backgroundSecondary)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(NapletColors.textSecondary)
            )
    }
}

// MARK: - Avatar Sizes
extension AvatarView {
    enum Size {
        case small      // 32pt
        case medium     // 48pt
        case large      // 64pt
        case xlarge     // 96pt
        case profile    // 120pt
        
        var value: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 64
            case .xlarge: return 96
            case .profile: return 120
            }
        }
    }
    
    /// Inicializador conveniente com tamanhos pré-definidos
    init(
        imageURL: String?,
        name: String?,
        size: Size,
        showBorder: Bool = true
    ) {
        self.imageURL = imageURL
        self.name = name
        self.size = size.value
        self.showBorder = showBorder
    }
}

// MARK: - Baby Avatar View
/// Variação específica para fotos de bebês
struct BabyAvatarView: View {
    let baby: Baby
    var size: AvatarView.Size = .medium
    var showBorder: Bool = true
    
    var body: some View {
        AvatarView(
            imageURL: baby.photoURL,
            name: baby.name,
            size: size,
            showBorder: showBorder
        )
    }
}

// MARK: - User Avatar View
/// Variação específica para fotos de usuários
struct UserAvatarView: View {
    let profile: Profile?
    var size: AvatarView.Size = .medium
    var showBorder: Bool = true
    
    var body: some View {
        AvatarView(
            imageURL: profile?.avatarUrl,
            name: profile?.displayName ?? profile?.email,
            size: size,
            showBorder: showBorder
        )
    }
}

// MARK: - Editable Avatar View
/// Avatar com overlay de câmera para edição
struct EditableAvatarView: View {
    let imageURL: String?
    let name: String?
    var size: AvatarView.Size = .profile
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    imageURL: imageURL,
                    name: name,
                    size: size,
                    showBorder: true
                )
                
                // Camera badge
                Circle()
                    .fill(NapletColors.primaryPurple)
                    .frame(width: size.value * 0.3, height: size.value * 0.3)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: size.value * 0.12))
                            .foregroundColor(.white)
                    )
                    .offset(x: -4, y: -4)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview("Avatar Variants") {
    ZStack {
        NapletColors.background
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: NapletSpacing.xl) {
                // Tamanhos
                Text("Sizes")
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)
                
                HStack(spacing: NapletSpacing.lg) {
                    AvatarView(imageURL: nil, name: "Ana Silva", size: .small)
                    AvatarView(imageURL: nil, name: "Ana Silva", size: .medium)
                    AvatarView(imageURL: nil, name: "Ana Silva", size: .large)
                    AvatarView(imageURL: nil, name: "Ana Silva", size: .xlarge)
                }
                
                // Variações
                Text("Variations")
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)
                
                HStack(spacing: NapletSpacing.lg) {
                    VStack {
                        AvatarView(imageURL: nil, name: nil, size: .large)
                        Text("No name").font(.caption)
                    }
                    
                    VStack {
                        AvatarView(imageURL: nil, name: "Maria", size: .large)
                        Text("One name").font(.caption)
                    }
                    
                    VStack {
                        AvatarView(imageURL: nil, name: "João Santos", size: .large)
                        Text("Full name").font(.caption)
                    }
                }
                .foregroundColor(NapletColors.textSecondary)
                
                // Com imagem real (placeholder URL)
                Text("With Image")
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)
                
                AvatarView(
                    imageURL: "https://i.pravatar.cc/150?img=32",
                    name: "Test User",
                    size: .profile
                )
                
                // Editável
                Text("Editable")
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)
                
                EditableAvatarView(
                    imageURL: nil,
                    name: "User Name",
                    size: .profile
                ) {
                    #if DEBUG
                    print("Edit avatar tapped")
                    #endif
                }
            }
            .padding()
        }
    }
}
