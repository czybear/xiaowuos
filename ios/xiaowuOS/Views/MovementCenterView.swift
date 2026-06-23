import SwiftUI

struct MovementCenterView: View {
    @State private var isShowingRunCompanion = false
    @State private var isShowingJumpRope = false
    @State private var isShowingWubuquan = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("跑步与运动辅助")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    runCompanionCard
                    runMetrics
                    assistTools
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("运动")
            .fullScreenCover(isPresented: $isShowingRunCompanion) {
                RunCompanionView()
            }
            .fullScreenCover(isPresented: $isShowingJumpRope) {
                JumpRopeView()
            }
            .fullScreenCover(isPresented: $isShowingWubuquan) {
                WubuquanView()
            }
        }
    }

    private var runCompanionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("跑步")
                .font(.headline)

            Text("实时关注心率、配速、步频")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("00:36:18")
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                    Text("当前训练时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("5.18 km")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("距离")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 18)

            ProgressView(value: 0.66)
                .tint(.orange)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var runMetrics: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
            MovementMetricTile(title: "心率", value: "146", tint: .red)
            MovementMetricTile(title: "配速", value: "6'18", tint: .orange)
            MovementMetricTile(title: "步频", value: "172", tint: .green)
        }
    }

    private var assistTools: some View {
        VStack(spacing: 14) {
            Button {
                isShowingRunCompanion = true
            } label: {
                MovementToolCard(
                    title: "跑步",
                    subtitle: "实时心率、配速、步频和有氧训练效果。",
                    status: "已可用",
                    systemImage: "lungs.fill",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

            Button {
                isShowingJumpRope = true
            } label: {
                MovementToolCard(
                    title: "跳绳",
                    subtitle: "计时、计数、组数和轻量挑战。",
                    status: "已可用",
                    systemImage: "figure.jumprope",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

            Button {
                isShowingWubuquan = true
            } label: {
                MovementToolCard(
                    title: "五步拳",
                    subtitle: "摄像头自动指导动作，协助打分和节奏练习。",
                    status: "试用中",
                    systemImage: "figure.martial.arts",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

            MovementToolCard(
                title: "PK 榜单",
                subtitle: "自定义标准，发起挑战。",
                status: "规划中",
                systemImage: "trophy.fill",
                tint: .purple
            )
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
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

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

private struct MovementMetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))

            ProgressView(value: 0.68)
                .tint(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    MovementCenterView()
        .environmentObject(RunSessionManager())
}
