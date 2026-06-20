import Foundation

@MainActor
final class OpsDashboardViewModel: ObservableObject {
    @Published private(set) var config = NodeConfigStore.load()
    @Published private(set) var nodes: [OpsNode] = []
    @Published private(set) var dashboard: DashboardStatus?
    @Published private(set) var ollama: [OllamaStatus] = []
    @Published private(set) var tasks: [OpsTask] = []
    @Published private(set) var logs: [OpsLog] = []
    @Published var statusMessage = "等待刷新"
    @Published var newTaskTitle = ""
    @Published var newTaskCommand = ""
    @Published var selectedNodeId = "xiaowuOSa"

    private lazy var client = OpsAPIClient(config: config)

    func refresh() {
        Task {
            do {
                async let nodes = client.loadNodes()
                async let dashboard = client.loadDashboard()
                async let ollama = client.loadOllama()
                async let tasks = client.loadTasks()
                async let logs = client.loadLogs()
                self.nodes = try await nodes
                self.dashboard = try await dashboard
                self.ollama = try await ollama
                self.tasks = try await tasks
                self.logs = try await logs
                statusMessage = "已连接 \(config.apiGatewayURL)"
            } catch {
                loadPreviewData()
                statusMessage = "使用本地预览，检查 API Gateway 配置"
            }
        }
    }

    func createTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let command = newTaskCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty || !command.isEmpty else { return }

        Task {
            do {
                let task = try await client.createTask(title: title.isEmpty ? "新任务" : title, command: command, targetNode: selectedNodeId)
                tasks.insert(task, at: 0)
                newTaskTitle = ""
                newTaskCommand = ""
                statusMessage = "任务已入队"
                await refreshQueues()
            } catch {
                statusMessage = "新增任务失败"
            }
        }
    }

    func triggerSync() {
        Task {
            do {
                try await client.triggerSync(nodeId: selectedNodeId)
                statusMessage = "同步请求已发送"
                await refreshQueues()
            } catch {
                statusMessage = "同步请求失败"
            }
        }
    }

    func restart(_ service: String) {
        Task {
            do {
                try await client.restart(service: service, nodeId: selectedNodeId)
                statusMessage = "\(service) 重启请求已发送"
                await refreshQueues()
            } catch {
                statusMessage = "\(service) 重启请求失败"
            }
        }
    }

    private func refreshQueues() async {
        if let logs = try? await client.loadLogs() {
            self.logs = logs
        }
        if let tasks = try? await client.loadTasks() {
            self.tasks = tasks
        }
    }

    private func loadPreviewData() {
        nodes = config.nodes.map {
            OpsNode(id: $0.id, role: $0.role, status: $0.id == "xiaowuOSc" ? "limited" : "configured", apiURL: $0.apiURL, ollamaURL: $0.ollamaURL, note: $0.note)
        }
        dashboard = DashboardStatus(ok: true, status: "preview", gateway: config.apiGatewayURL, healthEndpoint: config.healthEndpoint, loopGuard: "dedupe_key 防重复入队")
        ollama = config.nodes.filter { $0.id != "xiaowuOSc" }.map {
            OllamaStatus(nodeId: $0.id, status: $0.ollamaURL.isEmpty ? "missing_config" : "configured", url: $0.ollamaURL, note: "Ollama 必须配置 Windows IP")
        }
        tasks = [
            OpsTask(id: "preview-task", title: "检查 dashboard", command: "healthcheck dashboard", targetNode: "xiaowuOSa", status: "queued", source: "preview", dedupeKey: "preview-dashboard", createdAt: "", updatedAt: "")
        ]
        logs = [
            OpsLog(id: "preview-log", taskId: "preview-task", nodeId: "xiaowuOSa", level: "info", message: "本地预览日志：等待连接 API Gateway", createdAt: "")
        ]
    }
}
