import SwiftUI

struct ExploreCenterView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    assistantCard
                    actionList
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("探索")
        }
    }

    private var header: some View {
        Text("小游戏、AI 能力与 xiaowuOS 节点")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var assistantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("小悟助手")
                .font(.headline)

            Text("连接 xiaowuOS 服务端和 OpenClaw")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("开始探索")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.purple)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionList: some View {
        VStack(spacing: 14) {
            NavigationLink {
                RacingGameView()
            } label: {
                ExploreRow(symbol: "car.fill", title: "赛车", subtitle: "三车道躲避与收集小游戏", tint: .orange)
            }
            .buttonStyle(.plain)

            NavigationLink {
                OpsDashboardView()
            } label: {
                ExploreRow(symbol: "list.bullet.clipboard", title: "任务队列", subtitle: "新增任务、查看执行状态", tint: .purple)
            }
            .buttonStyle(.plain)

            NavigationLink {
                StudentManagementView()
            } label: {
                ExploreRow(symbol: "person.2.fill", title: "学员管理", subtitle: "班级、课时、积分、绑定状态", tint: .blue)
            }
            .buttonStyle(.plain)

            NavigationLink {
                OpsDashboardView()
            } label: {
                ExploreRow(symbol: "point.3.connected.trianglepath.dotted", title: "节点状态", subtitle: "xiaowuOSa / b / c", tint: .green)
            }
            .buttonStyle(.plain)

            NavigationLink {
                OpsDashboardView()
            } label: {
                ExploreRow(symbol: "brain.head.profile", title: "Ollama 连接", subtitle: "通过 API Gateway 检查", tint: .orange)
            }
            .buttonStyle(.plain)

            NavigationLink {
                OpsDashboardView()
            } label: {
                ExploreRow(symbol: "doc.text", title: "执行日志", subtitle: "查看 dashboard 与 worker 日志", tint: .blue)
            }
            .buttonStyle(.plain)

            NavigationLink {
                ChatCenterView()
            } label: {
                ExploreRow(symbol: "bubble.left.and.bubble.right.fill", title: "即时通讯", subtitle: "老师与学员交流", tint: .red)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ExploreRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ExploreCenterView()
}
