import SwiftUI

struct MovementCenterView: View {
    @State private var isShowingRunCompanion = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    assistTools
                    comingSoon
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("运动")
            .fullScreenCover(isPresented: $isShowingRunCompanion) {
                RunCompanionView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("运动辅助", systemImage: "figure.run.circle.fill")
                .font(.headline)

            Text("这里会放跑步、跳绳等运动陪伴功能，优先把实时数据、节奏提醒和训练反馈做好。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var assistTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("运动工具")
                .font(.headline)

            Button {
                isShowingRunCompanion = true
            } label: {
                MovementToolCard(
                    title: "跑步伴侣",
                    subtitle: "实时心率、配速、步频和有氧训练效果。",
                    status: "已可用",
                    systemImage: "figure.run",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

            MovementToolCard(
                title: "跳绳",
                subtitle: "后续支持计数、节奏、组间休息和训练记录。",
                status: "规划中",
                systemImage: "figure.jumprope",
                tint: .blue
            )
        }
    }

    private var comingSoon: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("训练方向")
                .font(.headline)

            HStack(spacing: 10) {
                MovementTag(title: "跑步", systemImage: "figure.run")
                MovementTag(title: "跳绳", systemImage: "figure.jumprope")
                MovementTag(title: "体能", systemImage: "figure.strengthtraining.traditional")
            }
        }
    }
}

private struct MovementToolCard: View {
    let title: String
    let subtitle: String
    let status: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(tint, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text(status)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(tint)
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MovementTag: View {
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
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    MovementCenterView()
        .environmentObject(RunSessionManager())
}
