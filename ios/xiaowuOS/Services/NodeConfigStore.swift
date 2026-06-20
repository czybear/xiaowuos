import Foundation

enum NodeConfigStore {
    static func load() -> NodeConfig {
        guard let url = Bundle.main.url(forResource: "NodeConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(NodeConfig.self, from: data) else {
            return .fallback
        }
        return config
    }
}
