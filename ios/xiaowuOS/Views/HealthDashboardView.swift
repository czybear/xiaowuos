import SwiftUI

struct HealthDashboardView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("心力、脑力、体力的平衡")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    balanceSection
                    todaySummary
                    healthActions
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

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("今日平衡")
                .font(.headline)

            Text("AI 暂按健康数据做基础估算")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let errorMessage = healthKitManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 18) {
                BalanceScore(title: "心力", score: 72, color: .green)
                BalanceScore(title: "脑力", score: 68, color: .blue)
                BalanceScore(title: "体力", score: 81, color: .orange)
            }

            if healthKitManager.isLoading {
                ProgressView()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var todaySummary: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
            HealthSummaryTile(title: "心率", value: bodyMetricValue(containing: "心率", fallback: "--"), color: .red)
            HealthSummaryTile(title: "步数", value: todayMetricValue(containing: "步数", fallback: "--"), color: .blue)
            HealthSummaryTile(title: "睡眠", value: bodyMetricValue(containing: "睡眠", fallback: "--"), color: .orange)
        }
    }

    private var healthActions: some View {
        VStack(spacing: 14) {
            HealthActionRow(symbol: "heart.fill", title: "健康数据授权", subtitle: "连接 iOS 健康数据", tint: .green)
            HealthActionRow(symbol: "waveform.path.ecg", title: "趋势记录", subtitle: "查看最近 7 天状态", tint: .blue)
            HealthActionRow(symbol: "sparkles", title: "AI 建议", subtitle: "先给出轻量提示", tint: .purple)
        }
    }

    private func todayMetricValue(containing keyword: String, fallback: String) -> String {
        healthKitManager.todayMetrics.first { $0.title.contains(keyword) }?.value ?? fallback
    }

    private func bodyMetricValue(containing keyword: String, fallback: String) -> String {
        healthKitManager.bodyMetrics.first { $0.title.contains(keyword) }?.value ?? fallback
    }
}

private struct BalanceScore: View {
    let title: String
    let score: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HealthSummaryTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ProgressView(value: 0.68)
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct HealthActionRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

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
