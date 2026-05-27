//
//  OutputLogView.swift
//  LocalizationsManager
//
//  Created by Adrián García García on 19/1/26.
//

import SwiftUI

struct OutputLogView: View {
    let events: [LogEvent]
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
                .disabled(events.isEmpty)
                .opacity(events.isEmpty ? 0.5 : 1.0)
            }
            .padding([.horizontal, .top])

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if events.isEmpty {
                            Text("No output yet...")
                                .font(.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        } else {
                            ForEach(events) { event in
                                Text(event.message.isEmpty ? " " : event.message)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .id(event.id)
                            }
                        }
                    }
                    .padding(12)
                }
                .task(id: events.last?.id) {
                    guard let lastEvent = events.last else { return }
                    proxy.scrollTo(lastEvent.id, anchor: .bottom)
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
