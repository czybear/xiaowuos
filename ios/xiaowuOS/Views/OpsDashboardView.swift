import SwiftUI

struct OpsDashboardView: View {
    @StateObject private var viewModel = OpsDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    nodeSection
                    dashboardSection
                    ollamaSection
                    taskSection
                    logSection
                    actionSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("节点控制台")
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("xiaowuOS V0.1", systemImage: "server.rack")
                .font(.headline)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("API Gateway：\(viewModel.config.apiGatewayURL)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var nodeSection: some View {
        OpsSection(title: "节点状态") {
            ForEach(viewModel.nodes) { node in
                OpsInfoRow(title: node.id, subtitle: node.note, value: "\(node.role) · \(node.status)", systemImage: "desktopcomputer")
            }
        }
    }

    private var dashboardSection: some View {
        OpsSection(title: "Dashboard") {
            OpsInfoRow(
                title: viewModel.dashboard?.status ?? "未知",
                subtitle: viewModel.dashboard?.loopGuard ?? "统一健康检查接口待连接",
                value: viewModel.dashboard?.healthEndpoint ?? "/health",
                systemImage: "gauge.with.dots.needle.bottom.50percent"
            )
        }
    }

    private var ollamaSection: some View {
        OpsSection(title: "Ollama") {
            ForEach(viewModel.ollama) { item in
                OpsInfoRow(title: item.nodeId, subtitle: item.note, value: item.status, systemImage: "brain.head.profile")
            }
        }
    }

    private var taskSection: some View {
        OpsSection(title: "任务队列") {
            VStack(spacing: 10) {
                TextField("任务标题", text: $viewModel.newTaskTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("任务命令或说明", text: $viewModel.newTaskCommand, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                Picker("目标节点", selection: $viewModel.selectedNodeId) {
                    ForEach(viewModel.config.nodes) { node in
                        Text(node.id).tag(node.id)
                    }
                }
                .pickerStyle(.segmented)
                Button {
                    viewModel.createTask()
                } label: {
                    Label("新增任务", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            ForEach(viewModel.tasks) { task in
                OpsInfoRow(title: task.title, subtitle: task.command.isEmpty ? task.dedupeKey : task.command, value: "\(task.targetNode) · \(task.status)", systemImage: "checklist")
            }
        }
    }

    private var logSection: some View {
        OpsSection(title: "执行日志") {
            ForEach(viewModel.logs) { log in
                OpsInfoRow(title: log.nodeId.isEmpty ? log.level : log.nodeId, subtitle: log.message, value: log.level, systemImage: "doc.text")
            }
        }
    }

    private var actionSection: some View {
        OpsSection(title: "手动操作") {
            HStack(spacing: 10) {
                Button {
                    viewModel.triggerSync()
                } label: {
                    Label("触发同步", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.restart("dashboard")
                } label: {
                    Label("重启 Dashboard", systemImage: "restart.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                viewModel.restart("worker")
            } label: {
                Label("重启 Worker", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct OpsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
    }
}

private struct OpsInfoRow: View {
    let title: String
    let subtitle: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title.isEmpty ? "未命名" : title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(value)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    OpsDashboardView()
}
