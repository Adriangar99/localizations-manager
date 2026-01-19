//
//  CountBadge.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .foregroundColor(.secondary)
    }
}
