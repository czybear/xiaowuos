import SwiftUI
import UIKit

struct WeChatDigestView: View {
    @State private var inputText = ""
    @State private var digest = WeChatDigest.empty

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                editor
                actions

                if digest.hasContent {
                    resultSection
                } else {
                    emptyHint
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("微信精华")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("把今天重要的微信消息粘贴进来。")
                .font(.headline)

            Text("xiaowuOS 会先在本机提炼重点、待办和需要跟进的人。暂不直接读取微信聊天记录。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var editor: some View {
        TextEditor(text: $inputText)
            .font(.body)
            .frame(minHeight: 180)
            .padding(12)
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("粘贴微信群、私聊或公众号消息...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                if let pasted = UIPasteboard.general.string {
                    inputText = pasted
                }
            } label: {
                Label("粘贴", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                digest = WeChatDigestEngine.makeDigest(from: inputText)
            } label: {
                Label("生成精华", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            DigestBlock(title: "今日重点", items: digest.highlights)
            DigestBlock(title: "待办", items: digest.todos)
            DigestBlock(title: "需要跟进", items: digest.followUps)
            DigestBlock(title: "提醒", items: digest.risks)
        }
    }

    private var emptyHint: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("适合每天睡前或开工前使用")
                .font(.headline)

            Text("复制一段微信消息，点“生成精华”，先把噪音压下去，把真正要处理的事拎出来。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DigestBlock: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            if items.isEmpty {
                Text("暂无")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct WeChatDigest {
    var highlights: [String]
    var todos: [String]
    var followUps: [String]
    var risks: [String]

    static let empty = WeChatDigest(highlights: [], todos: [], followUps: [], risks: [])

    var hasContent: Bool {
        !highlights.isEmpty || !todos.isEmpty || !followUps.isEmpty || !risks.isEmpty
    }
}

private enum WeChatDigestEngine {
    static func makeDigest(from text: String) -> WeChatDigest {
        let lines = normalizedLines(from: text)
        guard !lines.isEmpty else { return .empty }

        return WeChatDigest(
            highlights: pickHighlights(from: lines),
            todos: pickTodos(from: lines),
            followUps: pickFollowUps(from: lines),
            risks: pickRisks(from: lines)
        )
    }

    private static func normalizedLines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func pickHighlights(from lines: [String]) -> [String] {
        let keywords = ["重要", "通知", "安排", "确认", "报名", "课程", "作业", "截止", "时间", "费用", "考试", "活动"]
        let matched = lines.filter { line in
            keywords.contains { line.localizedCaseInsensitiveContains($0) }
        }
        return Array((matched.isEmpty ? lines : matched).prefix(5))
    }

    private static func pickTodos(from lines: [String]) -> [String] {
        let keywords = ["请", "需要", "记得", "麻烦", "帮忙", "提交", "回复", "确认", "完成", "准备", "发我", "填"]
        return Array(lines.filter { line in
            keywords.contains { line.localizedCaseInsensitiveContains($0) }
        }.prefix(6))
    }

    private static func pickFollowUps(from lines: [String]) -> [String] {
        let names = lines.compactMap { line -> String? in
            guard let separator = line.firstIndex(where: { $0 == ":" || $0 == "：" }) else { return nil }
            let name = String(line[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard (2...12).contains(name.count) else { return nil }
            return name
        }

        let uniqueNames = names.reduce(into: [String]()) { result, name in
            if !result.contains(name) {
                result.append(name)
            }
        }

        return Array(uniqueNames.prefix(5)).map { "关注 \($0) 的消息" }
    }

    private static func pickRisks(from lines: [String]) -> [String] {
        let keywords = ["紧急", "尽快", "迟到", "缺席", "退款", "投诉", "出错", "问题", "风险", "不能", "失败"]
        return Array(lines.filter { line in
            keywords.contains { line.localizedCaseInsensitiveContains($0) }
        }.prefix(5))
    }
}

#Preview {
    NavigationStack {
        WeChatDigestView()
    }
}
