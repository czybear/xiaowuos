import Foundation

struct StudentRecord: Codable, Identifiable, Equatable {
    var id: String { externalId }

    let externalId: String
    let studentName: String
    let phone: String
    let courseTitle: String
    let teacher: String
    let status: String
    let recordTime: String
    let remark: String
    let source: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case externalId = "external_id"
        case studentName = "student_name"
        case phone
        case courseTitle = "course_title"
        case teacher
        case status
        case recordTime = "record_time"
        case remark
        case source
        case updatedAt = "updated_at"
    }
}

struct StudentRecordListResponse: Decodable {
    let items: [StudentRecord]
    let count: Int
    let courses: [String]
    let statuses: [String]
}
