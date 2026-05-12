import Foundation

// MARK: - CATÁLOGO ENXUTO
// 10 milestones de exemplo (2 por categoria), texto em PT-BR inline.
// Expansão completa (30 milestones + localização EN/ES + chaves separadas)
// planejada para sprint dedicada após Sprint 1. O catálogo aqui é suficiente
// para a feature funcionar e o build passar.
//
// Referência futura: marcos do desenvolvimento da Sociedade Brasileira
// de Pediatria (SBP) e CDC Developmental Milestones.

// MARK: - Baby Milestone (record persistido)
// Linha em `baby_milestones` no Supabase representando 1 conquista atingida.

struct BabyMilestone: Codable, Identifiable, Equatable {
    let id: UUID
    let babyId: UUID
    let milestoneKey: String        // bate com `MilestoneDefinition.id`
    let achievedDate: String        // "yyyy-MM-dd" UTC
    let notes: String?
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case milestoneKey = "milestone_key"
        case achievedDate = "achieved_date"
        case notes
        case userId = "user_id"
    }

    /// Data efetiva (parse de `achievedDate`). Optional porque a View já trata `nil`.
    var achievedDateValue: Date? {
        BabyMilestone.dateParser.date(from: achievedDate)
    }

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Insert DTO

struct BabyMilestoneInsert: Codable {
    let babyId: UUID
    let milestoneKey: String
    let achievedDate: String
    let notes: String?
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case babyId = "baby_id"
        case milestoneKey = "milestone_key"
        case achievedDate = "achieved_date"
        case notes
        case userId = "user_id"
    }
}

// MARK: - Category

enum MilestoneCategory: String, CaseIterable, Identifiable {
    case grossMotor
    case fineMotor
    case socialEmotional
    case language
    case cognitive

    var id: String { rawValue }

    /// SF Symbol exibido no filtro de categoria e nas linhas de milestone.
    var iconName: String {
        switch self {
        case .grossMotor:      return "figure.walk"
        case .fineMotor:       return "hand.raised.fingers.spread"
        case .socialEmotional: return "face.smiling"
        case .language:        return "bubble.left.and.bubble.right"
        case .cognitive:       return "lightbulb"
        }
    }

    /// Chave de localização do nome da categoria.
    /// Strings adicionadas em Localizable.strings (PT/EN/ES) junto com este arquivo.
    var nameKey: String {
        switch self {
        case .grossMotor:      return "milestones.category.grossMotor"
        case .fineMotor:       return "milestones.category.fineMotor"
        case .socialEmotional: return "milestones.category.socialEmotional"
        case .language:        return "milestones.category.language"
        case .cognitive:       return "milestones.category.cognitive"
        }
    }
}

// MARK: - Status (computado em runtime pelo ViewModel)

enum MilestoneStatus {
    case achieved      // bebê já atingiu
    case expected      // dentro da janela esperada para a idade
    case upcoming      // ainda falta tempo
    case late          // passou da idade típica + 3 meses sem registrar
}

// MARK: - Milestone Definition (catálogo)
// Um marco do desenvolvimento. `id` é a chave estável (usada em `BabyMilestone.milestoneKey`).
// `name` e `description` estão hardcoded em PT-BR neste catálogo enxuto.
// Localização EN/ES virá no expansion sprint.

struct MilestoneDefinition: Identifiable, Equatable {
    let id: String                  // estável, snake_case com sufixo de idade
    let category: MilestoneCategory
    let expectedAgeMonths: Int
    let name: String                // PT-BR inline
    let description: String         // PT-BR inline

    /// SF Symbol exibido no ícone da linha do milestone.
    /// Por padrão usa o ícone da categoria; pode ser sobrescrito por marco.
    var iconName: String {
        category.iconName
    }
}

// MARK: - Catálogo
// Static API consumida por MilestoneRepository (progress) e MilestonesViewModel
// (filtros e listagem).

extension MilestoneDefinition {

    static let allMilestones: [MilestoneDefinition] = [
        // GROSS MOTOR
        MilestoneDefinition(
            id: "head_control_2m",
            category: .grossMotor,
            expectedAgeMonths: 2,
            name: "Sustenta a cabeça",
            description: "Consegue manter a cabeça erguida quando está de bruços."
        ),
        MilestoneDefinition(
            id: "sits_unsupported_8m",
            category: .grossMotor,
            expectedAgeMonths: 8,
            name: "Senta sem apoio",
            description: "Fica sentado sozinho por alguns minutos."
        ),

        // FINE MOTOR
        MilestoneDefinition(
            id: "grasps_object_3m",
            category: .fineMotor,
            expectedAgeMonths: 3,
            name: "Segura objetos",
            description: "Pega objetos colocados em sua mão."
        ),
        MilestoneDefinition(
            id: "pincer_grasp_9m",
            category: .fineMotor,
            expectedAgeMonths: 9,
            name: "Pinça com dedos",
            description: "Usa polegar e indicador para pegar coisas pequenas."
        ),

        // SOCIAL / EMOTIONAL
        MilestoneDefinition(
            id: "social_smile_2m",
            category: .socialEmotional,
            expectedAgeMonths: 2,
            name: "Sorriso social",
            description: "Sorri em resposta a outras pessoas."
        ),
        MilestoneDefinition(
            id: "recognizes_family_6m",
            category: .socialEmotional,
            expectedAgeMonths: 6,
            name: "Reconhece família",
            description: "Diferencia pais e familiares próximos."
        ),

        // LANGUAGE
        MilestoneDefinition(
            id: "babbling_6m",
            category: .language,
            expectedAgeMonths: 6,
            name: "Balbucia",
            description: "Faz sons como 'ba', 'da', 'ga'."
        ),
        MilestoneDefinition(
            id: "first_word_12m",
            category: .language,
            expectedAgeMonths: 12,
            name: "Primeira palavra",
            description: "Diz a primeira palavra com significado."
        ),

        // COGNITIVE
        MilestoneDefinition(
            id: "object_permanence_8m",
            category: .cognitive,
            expectedAgeMonths: 8,
            name: "Permanência de objeto",
            description: "Procura objetos escondidos."
        ),
        MilestoneDefinition(
            id: "imitates_gestures_12m",
            category: .cognitive,
            expectedAgeMonths: 12,
            name: "Imita gestos",
            description: "Reproduz gestos simples como bater palmas."
        ),
    ]

    /// Filtra o catálogo por categoria, mantendo a ordem do array original.
    static func milestones(for category: MilestoneCategory) -> [MilestoneDefinition] {
        allMilestones.filter { $0.category == category }
    }
}
