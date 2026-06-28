import Foundation

struct NodeConfig: Codable {
    var apiGatewayURL: String
    var healthEndpoint: String
    var dashboardEndpoint: String
    var nodes: [ConfiguredNode]

    static let fallback = NodeConfig(
        apiGatewayURL: "http://johnonlife.com:60030",
        healthEndpoint: "/health",
        dashboardEndpoint: "/api/ops/dashboard",
        nodes: [
            ConfiguredNode(id: "xiaowuOSa", role: "primary", apiURL: "http://johnonlife.com:60030", ollamaURL: "", note: "主控节点"),
            ConfiguredNode(id: "xiaowuOSb", role: "backup-worker", apiURL: "", ollamaURL: "", note: "备份/辅助执行节点"),
            ConfiguredNode(id: "xiaowuOSc", role: "external", apiURL: "", ollamaURL: "", note: "外部/云端/补充节点")
        ]
    )
}

struct ConfiguredNode: Codable, Identifiable {
    let id: String
    var role: String
    var apiURL: String
    var ollamaURL: String
    var note: String
}

struct OpsNode: Codable, Identifiable {
    let id: String
    var role: String
    var status: String
    var apiURL: String
    var ollamaURL: String
    var note: String

    enum CodingKeys: String, CodingKey {
        case id, role, status, note
        case apiURL = "api_url"
        case ollamaURL = "ollama_url"
    }
}

struct DashboardStatus: Codable {
    var ok: Bool?
    var status: String?
    var gateway: String?
    var healthEndpoint: String?
    var loopGuard: String?

    enum CodingKeys: String, CodingKey {
        case ok, status, gateway
        case healthEndpoint = "health_endpoint"
        case loopGuard = "loop_guard"
    }
}

struct OllamaStatus: Codable, Identifiable {
    var id: String { nodeId }
    var nodeId: String
    var status: String
    var url: String
    var note: String

    enum CodingKeys: String, CodingKey {
        case nodeId = "node_id"
        case status, url, note
    }
}

struct OpsTask: Codable, Identifiable {
    let id: String
    var title: String
    var command: String
    var targetNode: String
    var status: String
    var source: String
    var dedupeKey: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, command, status, source
        case targetNode = "target_node"
        case dedupeKey = "dedupe_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OpsLog: Codable, Identifiable {
    let id: String
    var taskId: String
    var nodeId: String
    var level: String
    var message: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, level, message
        case taskId = "task_id"
        case nodeId = "node_id"
        case createdAt = "created_at"
    }
}

struct OpsListResponse<T: Decodable>: Decodable {
    let items: [T]
    let count: Int
}

struct OpenClawMessageResponse: Decodable {
    let accepted: Bool
    let channel: String
    let targetNode: String
    let task: OpsTask

    enum CodingKeys: String, CodingKey {
        case accepted, channel, task
        case targetNode = "target_node"
    }
}
