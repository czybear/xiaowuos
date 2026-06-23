import Foundation

@MainActor
final class AccountManager: ObservableObject {
    @Published private(set) var currentMember: MemberProfile?
    @Published var loginMessage: String?

    private let memberDefaultsKey = "xiaowuOS.memberProfile"
    private let certifiedDeviceKey = "xiaowuOS.certifiedDevice"
    private let deviceIDKey = "xiaowuOS.deviceID"
    private let testAccounts: [TestAccount] = [
        TestAccount(
            phoneNumber: "18019360618",
            inviteCode: "JOHN",
            displayName: "澄木老师",
            realName: "澄木老师",
            avatarInitials: "澄",
            role: .superAdmin,
            memberLevel: .plus,
            source: .staff,
            enrolledCourses: CourseTrack.allCases,
            vipLevel: .vip12,
            growthPoints: 6_000
        ),
        TestAccount(
            phoneNumber: "15921046153",
            inviteCode: "WINDY",
            displayName: "雯雯老师",
            realName: "雯雯老师",
            avatarInitials: "雯",
            role: .admin,
            memberLevel: .plus,
            source: .staff,
            enrolledCourses: CourseTrack.allCases,
            vipLevel: .vip6,
            growthPoints: 1_150
        ),
        TestAccount(
            phoneNumber: "18616076028",
            inviteCode: "MIA",
            displayName: "小羽同学",
            realName: "小羽同学",
            avatarInitials: "羽",
            role: .student,
            memberLevel: .course,
            source: .direct,
            enrolledCourses: [.futureMaker],
            vipLevel: .vip3,
            growthPoints: 300
        )
    ]

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

    var deviceName: String {
        ProcessInfo.processInfo.hostName
    }

    var hasCertifiedDevice: Bool {
        UserDefaults.standard.bool(forKey: certifiedDeviceKey)
    }

    func signInWithCertifiedDevice(phoneNumber: String) {
        guard isValidPhoneNumber(phoneNumber) else {
            loginMessage = "请输入 11 位手机号。"
            return
        }

        guard hasCertifiedDevice else {
            loginMessage = "当前设备还未认证，请先使用邀请码完成首次注册。"
            return
        }

        currentMember = memberProfile(
            for: phoneNumber,
            provider: .device,
            fallback: MemberProfile(
            id: "phone-\(phoneNumber)",
            displayName: "手机用户 \(phoneNumber.suffix(4))",
            avatarInitials: "小悟",
            provider: .device,
            memberLevel: .course,
            source: .direct,
            enrolledCourses: CourseTrack.allCases,
            vipLevel: .vip0,
            growthPoints: 0,
            joinedAt: Date()
            )
        )
        loginMessage = nil
        persistCurrentMember()
    }

    func registerWithInvite(phoneNumber: String, inviteCode: String) {
        guard isValidPhoneNumber(phoneNumber) else {
            loginMessage = "请输入 11 位手机号。"
            return
        }

        let normalizedInviteCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let testAccount = testAccount(for: phoneNumber) {
            guard normalizedInviteCode == testAccount.inviteCode else {
                loginMessage = "手机号和邀请码不匹配。"
                return
            }

            currentMember = memberProfile(from: testAccount, provider: .inviteCode)
            loginMessage = nil
            UserDefaults.standard.set(true, forKey: certifiedDeviceKey)
            UserDefaults.standard.set(deviceID(), forKey: deviceIDKey)
            persistCurrentMember()
            return
        }

        guard normalizedInviteCode.count >= 6 else {
            loginMessage = "请输入有效的邀请码。"
            return
        }

        currentMember = MemberProfile(
            id: "phone-\(phoneNumber)",
            displayName: "手机用户 \(phoneNumber.suffix(4))",
            avatarInitials: "小悟",
            provider: .inviteCode,
            memberLevel: .course,
            source: source(from: normalizedInviteCode),
            enrolledCourses: CourseTrack.allCases,
            vipLevel: .vip0,
            growthPoints: 0,
            joinedAt: Date(),
            role: .student
        )
        loginMessage = nil
        UserDefaults.standard.set(true, forKey: certifiedDeviceKey)
        UserDefaults.standard.set(deviceID(), forKey: deviceIDKey)
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

    func updateProfile(
        displayName: String,
        realName: String,
        birthday: Date?,
        gender: MemberGender,
        city: String,
        school: String,
        grade: String,
        learningGoal: String,
        interests: [MemberInterest],
        guardianName: String,
        guardianPhone: String
    ) {
        guard var member = currentMember else { return }

        let normalizedDisplayName = normalizedText(displayName) ?? member.displayName
        member.displayName = normalizedDisplayName
        member.avatarInitials = avatarInitials(from: normalizedDisplayName)
        member.realName = normalizedText(realName)
        member.birthday = birthday
        member.gender = gender == .unspecified ? nil : gender
        member.city = normalizedText(city)
        member.school = normalizedText(school)
        member.grade = normalizedText(grade)
        member.learningGoal = normalizedText(learningGoal)
        member.interests = interests.isEmpty ? nil : interests
        member.guardianName = normalizedText(guardianName)
        member.guardianPhone = normalizedText(guardianPhone)

        currentMember = member
        persistCurrentMember()
    }

    private func loadStoredMember() {
        guard hasCertifiedDevice,
              let data = UserDefaults.standard.data(forKey: memberDefaultsKey) else {
            currentMember = nil
            return
        }

        currentMember = try? JSONDecoder().decode(MemberProfile.self, from: data)
        enrichStoredMemberIfNeeded()
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

    private func normalizedText(_ value: String) -> String? {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private func avatarInitials(from name: String) -> String {
        let text = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstCharacter = text.first else {
            return "小悟"
        }
        return String(firstCharacter).uppercased()
    }

    private func source(from inviteCode: String) -> MemberSource {
        if inviteCode.contains("LZ") {
            return .joint
        }
        if inviteCode.contains("QD") || inviteCode.contains("CHANNEL") {
            return .channel
        }
        if inviteCode.contains("SCHOOL") || inviteCode.contains("XQ") {
            return .school
        }
        return .direct
    }

    private func testAccount(for phoneNumber: String) -> TestAccount? {
        testAccounts.first { $0.phoneNumber == phoneNumber }
    }

    private func memberProfile(for phoneNumber: String, provider: LoginProvider, fallback: MemberProfile) -> MemberProfile {
        guard let testAccount = testAccount(for: phoneNumber) else {
            return fallback
        }
        return memberProfile(from: testAccount, provider: provider)
    }

    private func memberProfile(from account: TestAccount, provider: LoginProvider) -> MemberProfile {
        MemberProfile(
            id: "phone-\(account.phoneNumber)",
            displayName: account.displayName,
            avatarInitials: account.avatarInitials,
            provider: provider,
            memberLevel: account.memberLevel,
            source: account.source,
            enrolledCourses: account.enrolledCourses,
            vipLevel: account.vipLevel,
            growthPoints: account.growthPoints,
            joinedAt: Date(),
            role: account.role,
            realName: account.realName,
            gender: account.role == .student ? .boy : .adult
        )
    }

    private func enrichStoredMemberIfNeeded() {
        guard let currentMember else { return }
        let phoneNumber = currentMember.id.replacingOccurrences(of: "phone-", with: "")
        guard let testAccount = testAccount(for: phoneNumber) else { return }

        self.currentMember = memberProfile(from: testAccount, provider: currentMember.provider)
        persistCurrentMember()
    }

    private func deviceID() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey) {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: deviceIDKey)
        return id
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
            joinedAt: Date(),
            role: .superAdmin
        )
    }
}

private struct TestAccount {
    let phoneNumber: String
    let inviteCode: String
    let displayName: String
    let realName: String
    let avatarInitials: String
    let role: MemberRole
    let memberLevel: MemberLevel
    let source: MemberSource
    let enrolledCourses: [CourseTrack]
    let vipLevel: VIPLevel
    let growthPoints: Int
}
