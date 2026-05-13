//
//  AnalyticsService.swift
//  Naplet
//
//  Stub mínimo para tracking de eventos.
//  Loga via Logger em Debug. Quando PostHog/Firebase forem adicionados,
//  trocar apenas o corpo de `track` mantendo a API pública.
//
//  Nota: o Logger atual do projeto não expõe enum Category aberto.
//  Por isso o prefixo "[Analytics]" vai na própria string da mensagem,
//  consistente com o pattern usado em outros pontos do código (ex: "[RevenueCat]").
//

import Foundation

enum AnalyticsService {

    /// Registra um evento de analytics.
    /// - Parameters:
    ///   - event: Nome do evento (snake_case por convenção)
    ///   - properties: Propriedades opcionais do evento
    static func track(_ event: String, properties: [String: Any]? = nil) {
        #if DEBUG
        let propsString: String = {
            guard let props = properties, !props.isEmpty else { return "" }
            let pairs = props.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            return " { \(pairs) }"
        }()
        Logger.info("[Analytics] \(event)\(propsString)")
        #endif

        // TODO: Quando PostHog/Firebase Analytics for adicionado, integrar aqui.
        // Manter a API pública desta função inalterada.
    }

    /// Identifica o usuário atual para o serviço de analytics.
    /// Stub: apenas loga em Debug. Implementar quando SDK for adicionado.
    static func identify(userId: String, properties: [String: Any]? = nil) {
        #if DEBUG
        Logger.info("[Analytics] identify userId=\(userId)")
        #endif
        // TODO: Implementar identify do SDK escolhido.
    }
}
