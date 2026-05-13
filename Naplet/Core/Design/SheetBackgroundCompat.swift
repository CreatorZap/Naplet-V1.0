//
//  SheetBackgroundCompat.swift
//  Naplet
//
//  ViewModifier para compatibilidade do `.presentationBackground` em iOS 16.0-16.3.
//  Em iOS 16.4+ usa o modifier nativo. Em versões anteriores, aplica
//  `.background(...)` com ignoresSafeArea como fallback.
//
//  Uso típico em sheets do app:
//      .sheet(isPresented: $showFoo) {
//          FooView().modifier(SheetBackgroundCompat())
//      }
//
//  Originalmente criado dentro de AIConsentView.swift como `private struct`;
//  extraído aqui para reuso (OnboardingPaywallStepView e outros).
//

import SwiftUI

struct SheetBackgroundCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(NapletColors.background)
        } else {
            content.background(NapletColors.background.ignoresSafeArea())
        }
    }
}
