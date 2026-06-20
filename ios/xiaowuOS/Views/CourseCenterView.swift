import SwiftUI

struct CourseCenterView: View {
    @EnvironmentObject private var accountManager: AccountManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("学习")
        }
    }

    @ViewBuilder
    private var content: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    teacherChannel
                    messageEntry
                    discussionBoard
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 20) {
                    courseList
                    membershipRules
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            VStack(alignment: .leading, spacing: 20) {
                header
                teacherChannel
                messageEntry
                discussionBoard
                courseList
                membershipRules
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("澄木老师的三门课", systemImage: "graduationcap.fill")
                .font(.headline)

            Text("这里会成为澄木老师和学员们的交流平台，把课程、作业、答疑和成长记录连接起来。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var messageEntry: some View {
        NavigationLink {
            ChatCenterView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("即时通讯")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("学员之间、学员和老师之间交流，后续连接 OpenClaw 实时通道。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
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

    private var teacherChannel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("澄木老师")
                        .font(.headline)
                    Text("课程通知、答疑和作品点评")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                LearningAction(title: "发问题", systemImage: "questionmark.bubble.fill")
                LearningAction(title: "交作品", systemImage: "tray.and.arrow.up.fill")
                LearningAction(title: "看点评", systemImage: "text.bubble.fill")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var discussionBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交流动态")
                .font(.headline)

            LearningFeedRow(
                title: "本周主题",
                text: "用 AI 描述一个未来学习助手，并说明它能帮你解决什么问题。",
                systemImage: "sparkles"
            )
            LearningFeedRow(
                title: "学员作品",
                text: "未来创客作品区会展示搭建过程、照片和老师点评。",
                systemImage: "hammer.fill"
            )
        }
    }

    private var courseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前课程")
                .font(.headline)

            ForEach(CourseTrack.allCases) { course in
                CourseTrackCard(
                    course: course,
                    isEnabled: accountManager.currentMember?.enrolledCourses.contains(course) == true
                )
            }
        }
    }

    private var membershipRules: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("会员来源")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(MemberSource.allCases) { source in
                    Text(source.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(source == accountManager.currentMember?.source ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            source == accountManager.currentMember?.source ? Color.orange : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
    }
}

private struct LearningAction: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.orange)

            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LearningFeedRow: View {
    let title: String
    let text: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CourseTrackCard: View {
    let course: CourseTrack
    let isEnabled: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: course.systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(isEnabled ? Color.orange : Color.gray, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(course.title)
                        .font(.headline)
                    Spacer()
                    Text(isEnabled ? "已开通" : "待开通")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isEnabled ? .orange : .secondary)
                }

                Text(course.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CourseCenterView()
        .environmentObject(AccountManager())
}
