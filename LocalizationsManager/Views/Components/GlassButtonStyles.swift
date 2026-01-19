//
//  GlassButtonStyles.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    var color: Color
    var isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isProminent {
                        // Prominent style with solid color
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .opacity(configuration.isPressed ? 0.7 : 0.9)
                    } else {
                        // Subtle style with light background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(configuration.isPressed ? 0.15 : 0.1))
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                }
            )
            .foregroundColor(isProminent ? .white : color)
    }
}

// MARK: - Primary Glass Button
struct PrimaryGlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isProcessing: Bool
    let color: Color

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .blue,
        isProcessing: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isProcessing = isProcessing
        self.color = color
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(.white)
                }

                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .buttonStyle(GlassButtonStyle(color: color, isProminent: true))
        .disabled(isProcessing)
    }
}

// MARK: - Secondary Glass Button
struct SecondaryGlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let color: Color

    init(
        _ title: String,
        icon: String? = nil,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.color = color
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }

                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .buttonStyle(GlassButtonStyle(color: color, isProminent: false))
    }
}

// MARK: - Glass Card Background
struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                }
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

// MARK: - Glass Header Background
struct GlassHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    Rectangle()
                        .fill(Color.primary.opacity(0.03))

                    // Bottom border
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            )
    }
}

extension View {
    func glassHeader() -> some View {
        modifier(GlassHeader())
    }
}
