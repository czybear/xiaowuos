import CoreLocation
import SwiftUI

struct RunCompanionView: View {
    @EnvironmentObject private var runSessionManager: RunSessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        statusStrip
                        mainConsole
                        supportingMetrics
                    }
                    .padding(20)
                }

                controls
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("跑步伴侣")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        runSessionManager.requestLocationPermission()
                    } label: {
                        Image(systemName: "location.circle")
                    }
                }
            }
        }
    }

    private var statusStrip: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(statusColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.headline)
                Text(runSessionManager.locationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var mainConsole: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("本次跑步")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text(runSessionManager.distanceText)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                Text("距离")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 14) {
                RunValueTile(title: "时间", value: runSessionManager.elapsedText, systemImage: "timer")
                RunValueTile(title: "配速", value: runSessionManager.paceText, systemImage: "speedometer")
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var supportingMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("陪跑节奏")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                CompanionCue(
                    title: "起跑",
                    text: "前 10 分钟稳住呼吸，别急着冲。",
                    systemImage: "lungs.fill",
                    color: .teal
                )
                CompanionCue(
                    title: "巡航",
                    text: "配速稳定后，每公里听身体反馈。",
                    systemImage: "waveform.path",
                    color: .indigo
                )
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if runSessionManager.isRunning {
                Button {
                    runSessionManager.isPaused ? runSessionManager.resumeRun() : runSessionManager.pauseRun()
                } label: {
                    Label(runSessionManager.isPaused ? "继续" : "暂停", systemImage: runSessionManager.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    runSessionManager.finishRun()
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    runSessionManager.startRun()
                } label: {
                    Label("开始跑步", systemImage: "figure.run")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(16)
        .background(.regularMaterial)
    }

    private var statusTitle: String {
        if runSessionManager.isPaused { return "暂停中" }
        if runSessionManager.isRunning { return "我在陪你跑" }
        return "准备开跑"
    }

    private var statusIcon: String {
        if runSessionManager.isPaused { return "pause.fill" }
        if runSessionManager.isRunning { return "figure.run" }
        return "location.fill"
    }

    private var statusColor: Color {
        if runSessionManager.isPaused { return .gray }
        if runSessionManager.isRunning { return .green }
        return .orange
    }
}

private struct RunValueTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)

            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CompanionCue: View {
    let title: String
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    RunCompanionView()
        .environmentObject(RunSessionManager())
}
