//
//  OutputLogView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct OutputLogView: View {
    let outputLog: String
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Output Log")
                    .font(.headline)
                Spacer()
                SecondaryGlassButton(
                    "Copy",
                    icon: "doc.on.doc",
                    color: .blue,
                    action: onCopy
                )
                .disabled(outputLog.isEmpty)
                .opacity(outputLog.isEmpty ? 0.5 : 1.0)
            }
            .padding([.horizontal, .top])

            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        Text(outputLog.isEmpty ? "No output yet..." : outputLog)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(12)
                }
                .onChange(of: outputLog) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.02))

                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                }
            )
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 350, idealWidth: 400)
    }
}
