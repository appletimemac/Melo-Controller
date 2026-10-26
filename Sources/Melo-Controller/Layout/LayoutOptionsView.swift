//
//  LayoutOptionsView.swift
//  Melo-Controller
//
//  Created by Stossy11 on 26/1/2026.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var meloLayout: UTType { LayoutExporter.meloLayout }
}

struct LayoutOptionsView: View {
    let gameId: String?
    var gameName: String? = nil
    @Binding var layout: LayoutConfig
    var variant: ControllerLayoutVariant
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingResetAlert = false
    @State private var showingCopySheet = false
    @State private var showingFileImporter = false
    
    @State private var exportItem: LayoutExportItem?
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let gameId = gameId {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Game")
                                .font(.headline)
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundStyle(.blue)
                                Text(gameName ?? gameId)
                                    .font(.subheadline)
                                Spacer()
                                if LayoutManager.shared.hasCustomLayout(for: gameId, variant: variant) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Custom Layout")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.green)
                                } else {
                                    Text("Using Default")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1), in: .rect(cornerRadius: 8))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Layout Actions")
                            .font(.headline)
                        
                        Label(variant.title, systemImage: variant.systemImage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        actionRow("Copy Layout From…", systemImage: "doc.on.doc", color: .blue) {
                            showingCopySheet = true
                        }
                        
                        actionRow("Export Layout…", systemImage: "square.and.arrow.up", color: .purple, action: exportCurrentLayout)
                        
                        actionRow("Import Layout…", systemImage: "square.and.arrow.down", color: .teal) {
                            showingFileImporter = true
                        }
                        
                        actionRow("Reset to Default Layout", systemImage: "arrow.clockwise", color: .orange) {
                            layout = LayoutManager.shared.load(for: nil, variant: variant)
                        }
                        
                        actionRow("Delete Custom Layout", systemImage: "trash", color: .red) {
                            showingResetAlert = true
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Layout Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $exportItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.meloLayout, .json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("Delete Custom Layout", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                LayoutManager.shared.reset(for: gameId, variant: variant)
                layout = LayoutManager.shared.load(for: gameId, variant: variant)
            }
        } message: {
            Text("This will delete the custom layout for this game and revert to the default layout.")
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingCopySheet) {
            CopyLayoutView(targetGameId: gameId, layout: $layout, variant: variant)
        }
    }
    
    private func actionRow(_ title: LocalizedStringKey, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .padding()
            .background(color.opacity(0.1), in: .rect(cornerRadius: 8))
            .foregroundStyle(color)
        }
    }
    
    private func exportCurrentLayout() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(layout)
            
            let fileName = LayoutManager.shared.exportFileName(for: gameId, variant: variant)
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tmpURL, options: .atomic)
            exportItem = LayoutExportItem(url: tmpURL)
        } catch {
            alertTitle = "Export Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showingAlert = true
            
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            
            do {
                let data = try Data(contentsOf: url)
                let imported = try LayoutManager.shared.importLayout(from: data, for: gameId, variant: variant)
                layout = imported
                alertTitle = "Import Successful"
                alertMessage = "The layout has been applied\(gameId.map { " to \($0)" } ?? "")."
                showingAlert = true
            } catch {
                alertTitle = "Import Failed"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

private struct LayoutExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
