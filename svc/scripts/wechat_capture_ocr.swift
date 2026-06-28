#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation
import Vision

struct OCRItem: Encodable {
    let text: String
    let confidence: Float
    let box: [Double]
}

struct OCRPayload: Encodable {
    let source: String
    let mode: String
    let owner: String
    let windowID: UInt32
    let windowTitle: String
    let capturedAt: String
    let count: Int
    let items: [OCRItem]
    let notes: [String]
}

struct StatusPayload: Encodable {
    let ok: Bool
    let owner: String?
    let windowID: String?
    let count: String?
    let output: String?
    let error: String?
}

struct WindowCandidate {
    let id: UInt32
    let owner: String
    let title: String
    let bounds: CGRect
}

func argumentValue(_ name: String, default defaultValue: String) -> String {
    let args = CommandLine.arguments
    guard let index = args.firstIndex(of: name), index + 1 < args.count else {
        return defaultValue
    }
    return args[index + 1]
}

func hasFlag(_ name: String) -> Bool {
    CommandLine.arguments.contains(name)
}

func jsonPrint<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    if let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) {
        print(text)
    }
}

func errorExit(_ message: String, code: Int32 = 1) -> Never {
    jsonPrint(StatusPayload(ok: false, owner: nil, windowID: nil, count: nil, output: nil, error: message))
    exit(code)
}

func candidateWindows(ownerNeedle: String) -> [WindowCandidate] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return []
    }

    return rawWindows.compactMap { info in
        guard let owner = info[kCGWindowOwnerName as String] as? String,
              owner.localizedCaseInsensitiveContains(ownerNeedle),
              let number = info[kCGWindowNumber as String] as? UInt32,
              let layer = info[kCGWindowLayer as String] as? Int,
              layer == 0,
              let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
              bounds.width > 240,
              bounds.height > 240 else {
            return nil
        }
        let title = info[kCGWindowName as String] as? String ?? ""
        return WindowCandidate(id: number, owner: owner, title: title, bounds: bounds)
    }
    .sorted { lhs, rhs in
        lhs.bounds.width * lhs.bounds.height > rhs.bounds.width * rhs.bounds.height
    }
}

func recognizeText(in image: CGImage, fast: Bool) throws -> [OCRItem] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = fast ? .fast : .accurate
    request.recognitionLanguages = ["zh-Hans", "en-US"]
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([request])

    let observations = request.results ?? []
    return observations.compactMap { observation in
        guard let candidate = observation.topCandidates(1).first else { return nil }
        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else { return nil }
        let box = observation.boundingBox
        return OCRItem(
            text: text,
            confidence: candidate.confidence,
            box: [
                Double(box.origin.x),
                Double(box.origin.y),
                Double(box.size.width),
                Double(box.size.height),
            ]
        )
    }
}

func captureWindowImage(windowID: UInt32) throws -> CGImage {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("xiaowuos-wechat-\(windowID)-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-x", "-l", String(windowID), tempURL.path]
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(
            domain: "xiaowuOS.wechat.ocr",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "screencapture failed with status \(process.terminationStatus)"]
        )
    }

    guard let image = NSImage(contentsOf: tempURL),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw NSError(
            domain: "xiaowuOS.wechat.ocr",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "captured image is empty"]
        )
    }
    return cgImage
}

let ownerNeedle = argumentValue("--owner", default: "WeChat")
let outputPath = argumentValue("--output", default: "")
let fast = hasFlag("--fast")

let windows = candidateWindows(ownerNeedle: ownerNeedle)
guard !windows.isEmpty else {
    errorExit("没有找到可见的微信窗口，请先打开 Mac 微信并停留在一个聊天窗口。")
}

var selectedWindow: WindowCandidate?
var selectedImage: CGImage?
for window in windows {
    if let image = try? captureWindowImage(windowID: window.id) {
        selectedWindow = window
        selectedImage = image
        break
    }
}

guard let window = selectedWindow, let image = selectedImage else {
    errorExit("无法截取微信窗口。可能需要给 Codex/终端开启屏幕录制权限。", code: 2)
}

do {
    let rawItems = try recognizeText(in: image, fast: fast)
    var seen = Set<String>()
    let items = rawItems.filter { item in
        if seen.contains(item.text) { return false }
        seen.insert(item.text)
        return true
    }
    let payload = OCRPayload(
        source: "mac-wechat-window-ocr",
        mode: "read-only-visible-window-ocr",
        owner: window.owner,
        windowID: window.id,
        windowTitle: window.title,
        capturedAt: ISO8601DateFormatter().string(from: Date()),
        count: items.count,
        items: items,
        notes: [
            "只识别 Mac 微信当前可见窗口图像中的文字。",
            "不会读取微信数据库，不会发送消息，不会自动点击发送按钮。",
        ]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(payload)
    if !outputPath.isEmpty, outputPath != "-" {
        let url = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
        jsonPrint(StatusPayload(
            ok: true,
            owner: window.owner,
            windowID: String(window.id),
            count: String(items.count),
            output: outputPath,
            error: nil
        ))
    } else if let text = String(data: data, encoding: .utf8) {
        print(text)
    }
} catch {
    errorExit("OCR 识别失败：\(error.localizedDescription)")
}
