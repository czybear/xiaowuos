import SwiftUI

struct MemberCenterView: View {
    @EnvironmentObject private var accountManager: AccountManager

    private static let joinedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let member = accountManager.currentMember {
                        studentProfileCard(member)
                        profileInfoCard(member)
                        learningOverview(member)
                        roleFeatureCard(member)
                        courseList(member)
                        growthCard(member)
                        achievementsCard(member)
                        signOutButton
                    } else {
                        MemberSignInView()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(accountManager.isSignedIn ? "我的" : "小悟同学")
            .navigationBarTitleDisplayMode(accountManager.isSignedIn ? .large : .inline)
        }
    }

    private func studentProfileCard(_ member: MemberProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                Text(member.avatarInitials)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    Text(member.role?.title ?? "学员档案")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(member.displayName)
                        .font(.title2.weight(.semibold))

                    if let realName = member.realName {
                        Text("真实姓名：\(realName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(member.memberLevel.title) · \(member.source.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                MemberTag(text: maskedPhone(from: member.id))
                MemberTag(text: member.role?.title ?? "学员")
                MemberTag(text: "\(member.provider.title)登陆")
                MemberTag(text: "加入 \(Self.joinedDateFormatter.string(from: member.joinedAt))")
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func profileInfoCard(_ member: MemberProfile) -> some View {
        NavigationLink {
            ProfileEditView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("个人信息")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(profileCompletionText(member))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func learningOverview(_ member: MemberProfile) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            MemberMetricPill(title: "课程", value: "\(member.enrolledCourses.count) 门", subtitle: "已开通")
            MemberMetricPill(title: "角色", value: member.role?.title ?? "学员", subtitle: roleSubtitle(member.role))
            MemberMetricPill(title: "成长值", value: "\(member.growthPoints)", subtitle: member.vipLevel.title)
        }
    }

    private func roleFeatureCard(_ member: MemberProfile) -> some View {
        let role = member.role ?? .student

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("功能清单")
                    .font(.headline)

                Spacer()

                Text(role.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 12) {
                ForEach(role.featureGroups) { group in
                    RoleFeatureGroupView(group: group)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func courseList(_ member: MemberProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("我的课程")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(member.enrolledCourses) { course in
                    MemberCourseLine(course: course)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func growthCard(_ member: MemberProfile) -> some View {
        let displayedLevel = VIPGrowthPlan.currentLevel(from: member.growthPoints)
        let nextLevel = VIPGrowthPlan.nextLevel(after: displayedLevel)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("会员成长")
                        .font(.headline)
                    Text("\(displayedLevel.title) · \(displayedLevel.subtitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(growthTargetText(points: member.growthPoints, nextLevel: nextLevel))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }

            ProgressView(value: VIPGrowthPlan.progress(from: member.growthPoints, current: displayedLevel))
                .tint(.orange)

            Text(growthHint(points: member.growthPoints, nextLevel: nextLevel))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func achievementsCard(_ member: MemberProfile) -> some View {
        let achievements = AchievementPlan.achievements(for: member)
        let unlockedCount = achievements.filter(\.isUnlocked).count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("成就")
                    .font(.headline)

                Spacer()

                Text("\(unlockedCount) / \(achievements.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementLine(achievement: achievement)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func maskedPhone(from id: String) -> String {
        let rawPhone = id.replacingOccurrences(of: "phone-", with: "")
        guard rawPhone.count == 11 else {
            return "手机号已绑定"
        }

        return "\(rawPhone.prefix(3))****\(rawPhone.suffix(4))"
    }

    private func growthTargetText(points: Int, nextLevel: VIPLevel?) -> String {
        guard let nextLevel else {
            return "\(points) / MAX"
        }
        return "\(points) / \(nextLevel.requiredGrowthPoints)"
    }

    private func growthHint(points: Int, nextLevel: VIPLevel?) -> String {
        guard let nextLevel else {
            return "已达到 VIP12，后续以年度荣誉和成就收集为主。"
        }
        return "距离 \(nextLevel.title) · \(nextLevel.subtitle) 还差 \(max(0, nextLevel.requiredGrowthPoints - points)) 成长值。"
    }

    private func roleSubtitle(_ role: MemberRole?) -> String {
        switch role ?? .student {
        case .superAdmin:
            "全域管理"
        case .admin:
            "教学管理"
        case .student:
            "学习成长"
        }
    }

    private func profileCompletionText(_ member: MemberProfile) -> String {
        let finishedCount = [
            member.realName?.isEmpty == false,
            member.birthday != nil,
            member.city?.isEmpty == false,
            member.school?.isEmpty == false,
            member.interests?.isEmpty == false
        ].filter { $0 }.count

        if finishedCount >= 4 {
            return "资料已完善"
        }
        if let birthday = member.birthday {
            return "生日 \(birthday.formatted(.dateTime.month().day())) · 继续完善画像"
        }
        return "录入真实姓名、生日和兴趣标签"
    }

    private func profileCard(_ member: MemberProfile) -> some View {
        HStack(spacing: 14) {
            Text(member.avatarInitials)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.orange, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(member.displayName)
                    .font(.headline)
                Text("\(member.memberLevel.title) · \(member.source.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(member.vipLevel.title) · \(member.vipLevel.subtitle) · \(member.provider.title)登录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var opsEntry: some View {
        NavigationLink {
            OpsDashboardView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "server.rack")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("节点控制台")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("查看 a/b/c、dashboard、Ollama、任务队列和日志。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func vipGrowthCard(_ member: MemberProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP 成长")
                        .font(.headline)
                    Text("\(member.vipLevel.title) · \(member.vipLevel.subtitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(member.growthPoints) 成长值")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            ProgressView(value: VIPGrowthPlan.progress(from: member.growthPoints, current: VIPGrowthPlan.currentLevel(from: member.growthPoints)))
                .tint(.orange)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP0")
                        .font(.caption.weight(.semibold))
                    Text("体验玩家")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("VIP3")
                        .font(.caption.weight(.semibold))
                    Text("初级包月玩家")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(member.vipLevel == .vip3 ? "已开启初级包月权益。VIP4 及以上先保留，等课程和服务包更清楚后再定。" : "VIP0 可体验核心功能；升级到 VIP3 后进入初级包月权益。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("会员权益", systemImage: "person.badge.shield.checkmark.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                MemberBenefitRow(systemImage: "heart.text.square.fill", title: "健康数据同步", value: "已开启")
                MemberBenefitRow(systemImage: "figure.run.circle.fill", title: "跑步", value: "已开启")
                MemberBenefitRow(systemImage: "graduationcap.fill", title: "三门课程", value: "\(accountManager.currentMember?.enrolledCourses.count ?? 0) 门")
                MemberBenefitRow(systemImage: "trophy.fill", title: "PK 与榜单", value: "规划中")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            accountManager.signOut()
        } label: {
            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct MemberSignInView: View {
    @EnvironmentObject private var accountManager: AccountManager
    @State private var phoneNumber = "18012345678"
    @State private var inviteCode = "JOHN2026"
    @FocusState private var focusedField: SignInField?

    var body: some View {
        VStack(alignment: .center, spacing: 18) {
            signInHeader
            signInForm

            if let loginMessage = accountManager.loginMessage {
                Text(loginMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var signInHeader: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("xiaowuOS")
                .font(.largeTitle.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var signInForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("手机号", text: $phoneNumber)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .focused($focusedField, equals: .phone)
                .textFieldStyle(.plain)
                .contentShape(Rectangle())
                .padding(15)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    focusedField = .phone
                }

            TextField("邀请码", text: $inviteCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .code)
                .textFieldStyle(.plain)
                .contentShape(Rectangle())
                .padding(15)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    focusedField = .code
                }

            Button {
                focusedField = nil
                accountManager.registerWithInvite(phoneNumber: phoneNumber, inviteCode: inviteCode)
            } label: {
                Text("登陆")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("如需体验，请联系澄木老师。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ProfileEditView: View {
    @EnvironmentObject private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var realName = ""
    @State private var birthdayEnabled = false
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
    @State private var gender: MemberGender = .unspecified
    @State private var city = ""
    @State private var school = ""
    @State private var grade = ""
    @State private var learningGoal = ""
    @State private var selectedInterests: Set<MemberInterest> = []
    @State private var guardianName = ""
    @State private var guardianPhone = ""
    @State private var didLoadProfile = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                basicInfoCard
                learningProfileCard
                guardianCard
                saveButton
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("个人信息")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadProfileIfNeeded)
    }

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionTitle(title: "基础信息", subtitle: "昵称会显示在小悟同学里。")

            ProfileTextField(title: "显示昵称", placeholder: "例如 小羽同学", text: $displayName)
            ProfileTextField(title: "真实姓名", placeholder: "首次登录可录入", text: $realName)

            Toggle("录入生日", isOn: $birthdayEnabled)
                .font(.subheadline)

            if birthdayEnabled {
                DatePicker("生日", selection: $birthday, displayedComponents: .date)
                    .datePickerStyle(.compact)

                Text("生日当天会有惊喜哦！")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            Picker("身份", selection: $gender) {
                ForEach(MemberGender.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var learningProfileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionTitle(title: "学习画像", subtitle: "帮助老师更准确地安排课程和挑战。")

            ProfileTextField(title: "所在城市", placeholder: "例如 上海", text: $city)
            ProfileTextField(title: "学校 / 单位", placeholder: "选填", text: $school)
            ProfileTextField(title: "年级 / 阶段", placeholder: "例如 三年级、成人", text: $grade)

            VStack(alignment: .leading, spacing: 8) {
                Text("兴趣标签")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                FlowTagLayout(items: MemberInterest.allCases, selectedItems: selectedInterests) { interest in
                    toggleInterest(interest)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("学习目标")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("想提升什么？想做出什么作品？", text: $learningGoal, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var guardianCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionTitle(title: "联系信息", subtitle: "低龄学员建议填写家长信息。")

            ProfileTextField(title: "家长姓名", placeholder: "选填", text: $guardianName)
            ProfileTextField(title: "联系电话", placeholder: "选填", text: $guardianPhone)
                .keyboardType(.phonePad)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var saveButton: some View {
        Button {
            accountManager.updateProfile(
                displayName: displayName,
                realName: realName,
                birthday: birthdayEnabled ? birthday : nil,
                gender: gender,
                city: city,
                school: school,
                grade: grade,
                learningGoal: learningGoal,
                interests: Array(selectedInterests),
                guardianName: guardianName,
                guardianPhone: guardianPhone
            )
            dismiss()
        } label: {
            Text("保存")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func loadProfileIfNeeded() {
        guard didLoadProfile == false, let member = accountManager.currentMember else { return }
        didLoadProfile = true

        displayName = member.displayName
        realName = member.realName ?? ""
        if let birthdayValue = member.birthday {
            birthdayEnabled = true
            birthday = birthdayValue
        }
        gender = member.gender ?? .unspecified
        city = member.city ?? ""
        school = member.school ?? ""
        grade = member.grade ?? ""
        learningGoal = member.learningGoal ?? ""
        selectedInterests = Set(member.interests ?? [])
        guardianName = member.guardianName ?? ""
        guardianPhone = member.guardianPhone ?? ""
    }

    private func toggleInterest(_ interest: MemberInterest) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
}

private enum SignInField {
    case phone
    case code
}

private struct ProfileSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProfileTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct FlowTagLayout: View {
    let items: [MemberInterest]
    let selectedItems: Set<MemberInterest>
    let toggle: (MemberInterest) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                Button {
                    toggle(item)
                } label: {
                    Text(item.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(selectedItems.contains(item) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selectedItems.contains(item) ? Color.orange : Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct MemberTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MemberMetricPill: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MemberCourseLine: View {
    let course: CourseTrack

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: course.systemImage)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.subheadline.weight(.medium))

                Text(course.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("面向：\(course.targetAudience)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoleFeatureGroupView: View {
    let group: RoleFeatureGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.title)
                .font(.subheadline.weight(.medium))

            FlowLayout(tags: group.items)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlowLayout: View {
    let tags: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 84), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct MemberInfoLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(minHeight: 48)
    }
}

private struct AchievementLine: View {
    let achievement: MemberAchievement

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: achievement.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(achievement.isUnlocked ? .orange : .secondary)
                .frame(width: 30, height: 30)
                .background((achievement.isUnlocked ? Color.orange : Color.gray).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.subheadline.weight(.medium))

                Text(achievement.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(achievement.isUnlocked ? "已达成" : "未达成")
                .font(.caption.weight(.medium))
                .foregroundStyle(achievement.isUnlocked ? .orange : .secondary)
        }
    }
}

private struct MemberBenefitRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MemberCenterView()
        .environmentObject(AccountManager())
}
