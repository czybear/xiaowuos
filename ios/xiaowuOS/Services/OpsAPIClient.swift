import Foundation

final class OpsAPIClient {
    private let config: NodeConfig
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(config: NodeConfig) {
        self.config = config
    }

    func loadNodes() async throws -> [OpsNode] {
        let response: OpsListResponse<OpsNode> = try await get("/api/ops/nodes")
        return response.items
    }

    func loadDashboard() async throws -> DashboardStatus {
        try await get(config.dashboardEndpoint)
    }

    func loadOllama() async throws -> [OllamaStatus] {
        let response: OpsListResponse<OllamaStatus> = try await get("/api/ops/ollama")
        return response.items
    }

    func loadTasks() async throws -> [OpsTask] {
        let response: OpsListResponse<OpsTask> = try await get("/api/ops/tasks")
        return response.items
    }

    func loadLogs() async throws -> [OpsLog] {
        let response: OpsListResponse<OpsLog> = try await get("/api/ops/logs")
        return response.items
    }

    func createTask(title: String, command: String, targetNode: String) async throws -> OpsTask {
        try await post("/api/ops/tasks", payload: [
            "title": title,
            "command": command,
            "target_node": targetNode,
            "source": "ios",
            "dedupe_key": "\(targetNode):\(title):\(command)"
        ])
    }

    func triggerSync(nodeId: String) async throws {
        let _: ActionResponse = try await post("/api/ops/sync", payload: ["node_id": nodeId])
    }

    func restart(service: String, nodeId: String) async throws {
        let _: ActionResponse = try await post("/api/ops/restart", payload: ["service": service, "node_id": nodeId])
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: try url(for: path))
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Decodable, P: Encodable>(_ path: String, payload: P) async throws -> T {
        var request = URLRequest(url: try url(for: path))
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private func url(for path: String) throws -> URL {
        guard let baseURL = URL(string: config.apiGatewayURL) else {
            throw URLError(.badURL)
        }
        return baseURL.appending(path: path)
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

private struct ActionResponse: Decodable {
    let accepted: Bool
}
