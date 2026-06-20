import Foundation

@MainActor
final class AccountManager: ObservableObject {
    @Published private(set) var currentMember: MemberProfile?
    @Published var loginMessage: String?

    private let memberDefaultsKey = "xiaowuOS.memberProfile"

    var isSignedIn: Bool {
        currentMember != nil
    }

    init() {
        if ProcessInfo.processInfo.arguments.contains("-previewMember") {
            currentMember = Self.previewMember()
            persistCurrentMember()
            return
        }

        loadStoredMember()
    }

    func signInWithWeChat() {
        loginMessage = "微信联合登录需要先配置微信开放平台 AppID、Universal Link 和服务端换取 token。"
    }

    func requestOfficialAccountCode(phoneNumber: String) {
        guard isValidPhoneNumber(phoneNumber) else {
            loginMessage = "请输入 11 位手机号。"
            return
        }

        loginMessage = "已进入公众号验证码流程。开发阶段可输入 000000 体验登录，正式版会由服务端发送并校验验证码。"
    }

    func signInWithOfficialAccountCode(phoneNumber: String, code: String) {
        guard isValidPhoneNumber(phoneNumber) else {
            loginMessage = "请输入 11 位手机号。"
            return
        }

        guard code == "000000" else {
            loginMessage = "开发阶段验证码为 000000。正式版会由服务端校验公众号验证码。"
            return
        }

        currentMember = MemberProfile(
            id: "phone-\(phoneNumber)",
            displayName: "手机用户 \(phoneNumber.suffix(4))",
            avatarInitials: "小悟",
            provider: .officialAccountCode,
            memberLevel: .course,
            source: .direct,
            enrolledCourses: CourseTrack.allCases,
            vipLevel: .vip0,
            growthPoints: 0,
            joinedAt: Date()
        )
        loginMessage = nil
        persistCurrentMember()
    }

    func signInForPreview() {
        currentMember = Self.previewMember()
        loginMessage = nil
        persistCurrentMember()
    }

    func signOut() {
        currentMember = nil
        loginMessage = nil
        UserDefaults.standard.removeObject(forKey: memberDefaultsKey)
    }

    private func loadStoredMember() {
        guard let data = UserDefaults.standard.data(forKey: memberDefaultsKey) else {
            return
        }

        currentMember = try? JSONDecoder().decode(MemberProfile.self, from: data)
    }

    private func persistCurrentMember() {
        guard let currentMember else {
            UserDefaults.standard.removeObject(forKey: memberDefaultsKey)
            return
        }

        if let data = try? JSONEncoder().encode(currentMember) {
            UserDefaults.standard.set(data, forKey: memberDefaultsKey)
        }
    }

    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        phoneNumber.count == 11 && phoneNumber.allSatisfy(\.isNumber)
    }

    private static func previewMember() -> MemberProfile {
        MemberProfile(
            id: "preview-john",
            displayName: "John Chen",
            avatarInitials: "JC",
            provider: .preview,
            memberLevel: .course,
            source: .direct,
            enrolledCourses: CourseTrack.allCases,
            vipLevel: .vip3,
            growthPoints: 300,
            joinedAt: Date()
        )
    }
}
