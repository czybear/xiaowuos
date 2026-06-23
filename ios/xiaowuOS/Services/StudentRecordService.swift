import Foundation

@MainActor
final class StudentRecordViewModel: ObservableObject {
    @Published private(set) var records: [StudentRecord] = []
    @Published private(set) var courses: [String] = []
    @Published private(set) var statuses: [String] = []
    @Published private(set) var isLoading = false
    @Published var query = ""
    @Published var selectedCourse = ""
    @Published var selectedStatus = ""
    @Published var errorMessage: String?

    private let config = NodeConfigStore.load()

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: StudentRecordListResponse = try await get(path: "/api/student-records", queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "course_title", value: selectedCourse),
                URLQueryItem(name: "status", value: selectedStatus),
            ])
            records = response.items
            courses = response.courses
            statuses = response.statuses
        } catch {
            errorMessage = "学员数据暂时不可用"
        }
    }

    func resetFilters() async {
        query = ""
        selectedCourse = ""
        selectedStatus = ""
        await load()
    }

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard let baseURL = URL(string: config.apiGatewayURL) else {
            throw URLError(.badURL)
        }
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.filter { ($0.value ?? "").isEmpty == false }
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
