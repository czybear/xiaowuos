import SwiftUI

struct OpenClawBridgeView: View {
    @StateObject private var viewModel = OpenClawBridgeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statusCard
                inputCard
                outputCard
                taskCard
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("联接小悟")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("OpenClaw 通道")
                    .font(.headline)

                Spacer()

                Text(viewModel.connectionText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.isConnected ? .green : .orange)
            }

            Text(viewModel.config.apiGatewayURL)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Picker("节点", selection: $viewModel.selectedNodeId) {
                ForEach(viewModel.config.nodes) { node in
                    Text(node.id).tag(node.id)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输入")
                .font(.headline)

            TextEditor(text: $viewModel.messageText)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 10) {
                Button {
                    viewModel.useTemplate("帮我查看当前任务队列")
                } label: {
                    Text("任务队列")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.useTemplate("请同步 xiaowuOSa 和 xiaowuOSb")
                } label: {
                    Text("同步节点")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                viewModel.send()
            } label: {
                Label(viewModel.isSending ? "发送中" : "发送给小悟", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.canSend == false)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输出")
                .font(.headline)

            if viewModel.messages.isEmpty {
                OpenClawBubble(text: "等待输入", detail: "xiaowuOS app 会把消息送到 OpenClaw 任务通道。", isUser: false)
            } else {
                ForEach(viewModel.messages) { message in
                    OpenClawBubble(text: message.text, detail: message.detail, isUser: message.isUser)
                }
            }
        }
    }

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近回执")
                .font(.headline)

            ForEach(viewModel.recentTasks.prefix(3)) { task in
                OpenClawReceiptRow(title: task.title, subtitle: task.command, value: "\(task.targetNode) · \(task.status)")
            }

            ForEach(viewModel.recentLogs.prefix(3)) { log in
                OpenClawReceiptRow(title: log.nodeId, subtitle: log.message, value: log.level)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

@MainActor
private final class OpenClawBridgeViewModel: ObservableObject {
    @Published private(set) var config = NodeConfigStore.load()
    @Published var selectedNodeId = "xiaowuOSa"
    @Published var messageText = ""
    @Published private(set) var isSending = false
    @Published private(set) var isConnected = false
    @Published private(set) var connectionText = "待连接"
    @Published private(set) var messages: [OpenClawChatLine] = []
    @Published private(set) var recentTasks: [OpsTask] = []
    @Published private(set) var recentLogs: [OpsLog] = []

    private let client: OpsAPIClient

    var canSend: Bool {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && isSending == false
    }

    init() {
        let config = NodeConfigStore.load()
        self.config = config
        self.selectedNodeId = config.nodes.first?.id ?? "xiaowuOSa"
        self.client = OpsAPIClient(config: config)
    }

    func refresh() {
        Task {
            do {
                async let dashboard = client.loadDashboard()
                async let tasks = client.loadTasks()
                async let logs = client.loadLogs()
                let dashboardStatus = try await dashboard
                recentTasks = try await tasks
                recentLogs = try await logs
                isConnected = dashboardStatus.ok ?? false
                connectionText = isConnected ? "已连接" : (dashboardStatus.status ?? "未知")
            } catch {
                isConnected = false
                connectionText = "连接失败"
            }
        }
    }

    func useTemplate(_ text: String) {
        messageText = text
    }

    func send() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false, isSending == false else { return }

        isSending = true
        messages.append(OpenClawChatLine(text: text, detail: selectedNodeId, isUser: true))

        Task {
            do {
                let response = try await client.sendOpenClawMessage(
                    message: text,
                    targetNode: selectedNodeId,
                    channel: "xiaowuOS-app"
                )
                messages.append(OpenClawChatLine(
                    text: "已进入 OpenClaw 通道",
                    detail: "\(response.targetNode) · \(response.task.status)",
                    isUser: false
                ))
                messageText = ""
                refresh()
            } catch {
                messages.append(OpenClawChatLine(
                    text: "发送失败",
                    detail: error.localizedDescription,
                    isUser: false
                ))
            }
            isSending = false
        }
    }
}

private struct OpenClawChatLine: Identifiable {
    let id = UUID()
    let text: String
    let detail: String
    let isUser: Bool
}

private struct OpenClawBubble: View {
    let text: String
    let detail: String
    let isUser: Bool

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 36)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isUser ? .white : .primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(isUser ? .white.opacity(0.78) : .secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .background(isUser ? Color.orange : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            if isUser == false {
                Spacer(minLength: 36)
            }
        }
    }
}

private struct OpenClawReceiptRow: View {
    let title: String
    let subtitle: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "OpenClaw" : title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        OpenClawBridgeView()
    }
}
