import SwiftUI

struct CourseCenterView: View {
    @EnvironmentObject private var accountManager: AccountManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("澄木老师的三门课")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    pomodoroCard
                    scheduleCard
                    courseList
                    learningRecord
                    materialEntry
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("学习")
        }
    }

    private var pomodoroCard: some View {
        NavigationLink {
            PomodoroTimerView()
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日专注")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("番茄钟")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("25:00")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日安排")
                    .font(.headline)

                Spacer()

                Text("学习节奏")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                LearningScheduleRow(time: "16:00", title: "未来创客", note: "作品搭建")
                LearningScheduleRow(time: "20:30", title: "番茄钟", note: "25 分钟专注")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var courseList: some View {
        VStack(spacing: 14) {
            ForEach(CourseTrack.allCases) { course in
                CourseTrackCard(
                    course: course,
                    isEnabled: accountManager.currentMember?.enrolledCourses.contains(course) == true
                )
            }
        }
    }

    private var learningRecord: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("学习记录")
                    .font(.headline)

                Spacer()

                Text("查看全部")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
            }

            Text("最近一次：未来创客 · 作品搭建")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var materialEntry: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "book.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("课程资料")
                    .font(.headline)

                Text("课件、作业、作品记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LearningScheduleRow: View {
    let time: String
    let title: String
    let note: String

    var body: some View {
        HStack(spacing: 12) {
            Text(time)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .monospacedDigit()
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct CourseTrackCard: View {
    let course: CourseTrack
    let isEnabled: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: course.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.headline)

                Text(course.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var tint: Color {
        switch course {
        case .scienceInnovation:
            .green
        case .futureMaker:
            .orange
        case .artificialIntelligence:
            .purple
        }
    }
}

#Preview {
    CourseCenterView()
        .environmentObject(AccountManager())
}
