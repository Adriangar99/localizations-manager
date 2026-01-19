//
//  ListSectionHeader.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct ListSectionHeader: View {
    let title: String
    let count: Int
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                CountBadge(count: count)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
