import SwiftUI

struct HealthDashboardView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    balanceSection

                    MetricSection(title: "今天", metrics: healthKitManager.todayMetrics)
                    MetricSection(title: "身体状态", metrics: healthKitManager.bodyMetrics)

                    recentRuns
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("健康")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        healthKitManager.refreshHealthData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(healthKitManager.isLoading)
                }
            }
            .onAppear {
                if healthKitManager.todayMetrics.isEmpty {
                    healthKitManager.requestAuthorizationAndRefresh()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("xiaowuOS")
                        .font(.headline)
                    Text("心力、脑力、体力平衡观察")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if healthKitManager.isLoading {
                    ProgressView()
                }
            }

            Text("当前算法为体验模型，后续会结合健康数据、学习状态和运动记录继续调整。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage = healthKitManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 平衡")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                BalanceCard(title: "心力", score: 72, status: "稳定", systemImage: "heart.fill", color: .red)
                BalanceCard(title: "脑力", score: 68, status: "可提升", systemImage: "brain.head.profile", color: .purple)
                BalanceCard(title: "体力", score: 81, status: "较好", systemImage: "bolt.fill", color: .green)
            }

            Text("建议：今天保持轻中强度运动，学习任务拆成 25 分钟一段，晚上留出恢复时间。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var recentRuns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近跑步")
                .font(.headline)

            if healthKitManager.recentRuns.isEmpty {
                EmptyStateView(title: "还没有读取到跑步记录", systemImage: "figure.run")
            } else {
                VStack(spacing: 10) {
                    ForEach(healthKitManager.recentRuns) { run in
                        RunHistoryRow(run: run)
                    }
                }
            }
        }
    }
}

private struct BalanceCard: View {
    let title: String
    let score: Int
    let status: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)

            Text("\(score)")
                .font(.title2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MetricSection: View {
    let title: String
    let metrics: [HealthMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if metrics.isEmpty {
                EmptyStateView(title: "等待健康数据", systemImage: "heart")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(metrics) { metric in
                        MetricCard(metric: metric)
                    }
                }
            }
        }
    }
}

private struct MetricCard: View {
    let metric: HealthMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: metric.systemImage)
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(metric.value)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(metric.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(metric.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RunHistoryRow: View {
    let run: RunWorkout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.blue, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(Formatters.shortDate(run.date))
                    .font(.subheadline.weight(.semibold))
                Text("\(Formatters.distance(run.distanceMeters)) · \(Formatters.stopwatch(run.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(run.paceSecondsPerKilometer.map(Formatters.pace) ?? "--")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
