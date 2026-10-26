//
//  LayoutManager.swift
//  Melo-Controller
//
//  Created by Stossy11 on 04/12/2025.
//

import Foundation
import UniformTypeIdentifiers

enum LayoutTransferError: LocalizedError {
    case encodingFailed
    case decodingFailed(underlying: Error)
    case fileWriteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode the layout."
        case .decodingFailed(let e):
            return "The file doesn't appear to be a valid layout: \(e.localizedDescription)"
        case .fileWriteFailed(let e):
            return "Could not write the layout file: \(e.localizedDescription)"
        }
    }
}

/// App-Side editable types
public class LayoutExporter {
    public static var fileType = "meloLayout"
    
    public static var meloLayout = UTType(exportedAs: "com.stossy11.melocontroller.layout",
                                   conformingTo: .data)
}

/// Stores one layout per game (or the default) and per variant.
///
/// The landscape layout keeps the file names layouts have always had (`<id>.json`, `default.json`), so
/// existing layouts stay valid. The portrait layout adds `<id>.portrait.json` and `default.portrait.json`.
/// A portrait layout that was never saved falls back through `<id>.json`, `default.portrait.json` and
/// `default.json`, which is what the single shared layout used to give.
class LayoutManager {
    static let shared = LayoutManager()
    private init() {}

    private static let portraitSuffix = ".portrait"

    private var baseURL: URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent("controller_layouts")
    }

    private func baseName(for gameId: String?) -> String {
        gameId?.isEmpty == false ? gameId! : "default"
    }

    private func fileURL(for gameId: String?, variant: ControllerLayoutVariant) -> URL {
        let suffix = variant == .portrait ? Self.portraitSuffix : ""
        return baseURL.appendingPathComponent("\(baseName(for: gameId))\(suffix).json")
    }

    /// Files to try, most specific first.
    private func loadChain(for gameId: String?, variant: ControllerLayoutVariant) -> [URL] {
        var chain: [URL] = []
        if gameId?.isEmpty == false {
            if variant == .portrait { chain.append(fileURL(for: gameId, variant: .portrait)) }
            chain.append(fileURL(for: gameId, variant: .landscape))
        }
        if variant == .portrait { chain.append(fileURL(for: nil, variant: .portrait)) }
        chain.append(fileURL(for: nil, variant: .landscape))
        return chain
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    private func decodeLayout(at url: URL) -> LayoutConfig? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(LayoutConfig.self, from: data)
    }

    func save(_ layout: LayoutConfig, for gameId: String? = nil, variant: ControllerLayoutVariant = .landscape) {
        ensureDirectoryExists()
        try? JSONEncoder().encode(layout).write(to: fileURL(for: gameId, variant: variant))
    }

    func load(for gameId: String? = nil, variant: ControllerLayoutVariant = .landscape) -> LayoutConfig {
        for url in loadChain(for: gameId, variant: variant) {
            if let config = decodeLayout(at: url) { return config }
        }
        return LayoutConfig()
    }
    
    func loadLegacy(for gameId: String? = nil) -> [String: ButtonLayout] {
        let url = fileURL(for: gameId, variant: .landscape)
        guard let data = try? Data(contentsOf: url),
              let legacyConfig = try? JSONDecoder().decode([String: ButtonLayout].self, from: data) else {
            return [:]
        }
        return legacyConfig
    }

    /// Rewrites a layout file saved in the oldest format (a bare dictionary of buttons) in the current one.
    func migrateLegacyLayout(for gameId: String? = nil) {
        let legacy = loadLegacy(for: gameId)
        guard !legacy.isEmpty, decodeLayout(at: fileURL(for: gameId, variant: .landscape)) == nil else { return }
        var layout = LayoutConfig()
        layout.buttons = legacy
        save(layout, for: gameId, variant: .landscape)
    }

    func reset(for gameId: String? = nil, variant: ControllerLayoutVariant = .landscape) {
        try? FileManager.default.removeItem(at: fileURL(for: gameId, variant: variant))
    }

    func resetAll() {
        try? FileManager.default.removeItem(at: baseURL)
    }

    /// Whether the game has a layout of its own that applies to this variant.
    func hasCustomLayout(for gameId: String, variant: ControllerLayoutVariant = .landscape) -> Bool {
        let own = variant == .portrait
            ? [fileURL(for: gameId, variant: .portrait), fileURL(for: gameId, variant: .landscape)]
            : [fileURL(for: gameId, variant: .landscape)]
        return own.contains { FileManager.default.fileExists(atPath: $0.path) }
    }

    func copyLayout(from sourceGameId: String?, to targetGameId: String?, variant: ControllerLayoutVariant = .landscape) {
        save(load(for: sourceGameId, variant: variant), for: targetGameId, variant: variant)
    }

    /// Every game that has a saved layout, each listed once however many variants it has.
    func getAllGameLayouts() -> [String] {
        ensureDirectoryExists()
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: nil
        ) else { return [] }
        var games = Set<String>()
        for url in files {
            let filename = url.lastPathComponent
            guard filename.hasSuffix(".json") else { continue }
            var name = String(filename.dropLast(".json".count))
            if name.hasSuffix(Self.portraitSuffix) { name = String(name.dropLast(Self.portraitSuffix.count)) }
            if !name.isEmpty, name != "default" { games.insert(name) }
        }
        return games.sorted()
    }
    
    func exportLayout(for gameId: String? = nil, variant: ControllerLayoutVariant = .landscape) throws -> Data {
        let layout = load(for: gameId, variant: variant)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(layout) else {
            throw LayoutTransferError.encodingFailed
        }
        return data
    }
    
    func exportFileName(for gameId: String? = nil, variant: ControllerLayoutVariant = .landscape) -> String {
        let suffix = variant == .portrait ? Self.portraitSuffix : ""
        return "\(baseName(for: gameId))\(suffix).\(LayoutExporter.fileType)"
    }
    
    @discardableResult
    func importLayout(from data: Data, for gameId: String? = nil, variant: ControllerLayoutVariant = .landscape) throws -> LayoutConfig {
        do {
            let layout = try JSONDecoder().decode(LayoutConfig.self, from: data)
            save(layout, for: gameId, variant: variant)
            return layout
        } catch {
            throw LayoutTransferError.decodingFailed(underlying: error)
        }
    }
}
