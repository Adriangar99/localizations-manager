//
//  LocalizationKeyRow.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct LocalizationKeyRow: View {
    let key: LocalizationKey
    let isSelected: Bool
    let highlightColor: Color
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key.key)
                .font(.system(.body, design: .monospaced))
            Text(key.value)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected
                    ? highlightColor.opacity(0.15)
                    : Color.primary.opacity(0.04))
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .simultaneousGesture(
            TapGesture(count: 1).onEnded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onSingleTap()
                }
            }
        )
    }
}
