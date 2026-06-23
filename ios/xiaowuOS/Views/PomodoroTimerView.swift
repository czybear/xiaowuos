import AVFoundation
import AudioToolbox
import SwiftUI

struct PomodoroTimerView: View {
    @StateObject private var timer = PomodoroTimer()
    @StateObject private var soundPlayer = FocusSoundPlayer()
    @State private var focusTask = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusCard
                    taskCard
                    timerCard
                    modeCard
                    soundCard
                    reviewCard
                    tipsCard
                }
                .padding(20)
                .padding(.bottom, 18)
            }

            controls
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("番茄钟")
        .onAppear {
            timer.onRoundFinished = {
                soundPlayer.playCompletionBell()
            }
        }
        .onDisappear {
            timer.pause()
            soundPlayer.stopNoise()
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: timer.mode.systemImage)
                .font(.title3)
                .foregroundStyle(timer.mode.tint)
                .frame(width: 42, height: 42)
                .background(timer.mode.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(timer.statusTitle)
                    .font(.headline)

                Text(timer.mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前任务")
                .font(.headline)

            TextField("这一个番茄钟只做一件事", text: $focusTask, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Text("参考番茄钟任务清单的思路：先定任务，再开始计时。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(timer.remainingText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("今日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(timer.completedFocusCount) 次")
                        .font(.title3.weight(.semibold))
                }
            }

            ProgressView(value: timer.progress)
                .tint(timer.mode.tint)

            Text(timer.progressHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("模式")
                .font(.headline)

            Picker("模式", selection: $timer.mode) {
                ForEach(PomodoroMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(timer.isRunning)

            HStack(spacing: 10) {
                PomodoroMetric(title: "专注", value: "25 分钟")
                PomodoroMetric(title: "短休息", value: "5 分钟")
                PomodoroMetric(title: "长休息", value: "15 分钟")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var soundCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("专注音景")
                    .font(.headline)

                Spacer()

                Text(soundPlayer.isNoiseEnabled ? "播放中" : "已关闭")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(soundPlayer.isNoiseEnabled ? .orange : .secondary)
            }

            Toggle("白噪声辅助专注", isOn: Binding(
                get: { soundPlayer.isNoiseEnabled },
                set: { soundPlayer.setNoiseEnabled($0) }
            ))
            .font(.subheadline)

            Picker("声音", selection: Binding(
                get: { soundPlayer.scene },
                set: { soundPlayer.selectScene($0) }
            )) {
                ForEach(FocusSoundScene.allCases) { scene in
                    Text(scene.title).tag(scene)
                }
            }
            .pickerStyle(.segmented)
            .disabled(soundPlayer.isNoiseEnabled == false)

            VStack(alignment: .leading, spacing: 8) {
                Text("音量")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { soundPlayer.volume },
                        set: { soundPlayer.setVolume($0) }
                    ),
                    in: 0.05...0.45
                )
                .disabled(soundPlayer.isNoiseEnabled == false)
            }

            Text("到时间后会自动响一声提醒。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日回顾")
                .font(.headline)

            HStack(spacing: 10) {
                PomodoroMetric(title: "完成", value: "\(timer.completedFocusCount) 个")
                PomodoroMetric(title: "专注时长", value: "\(timer.completedFocusCount * 25) 分钟")
                PomodoroMetric(title: "节奏", value: "25 / 5")
            }

            Text(timer.completedFocusCount == 0 ? "先完成一个番茄钟，今天的专注记录就开始了。" : "已经完成 \(timer.completedFocusCount) 个番茄钟，继续保持。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("专注提示")
                .font(.headline)

            PomodoroTip(title: "只做一件事", text: "开始后先把这 25 分钟留给一个明确任务。")
            PomodoroTip(title: "休息要真的休息", text: "短休息时离开屏幕，喝水或伸展一下。")
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if timer.isRunning {
                Button {
                    timer.pause()
                } label: {
                    Label("暂停", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                Button {
                    timer.start()
                } label: {
                    Label(timer.remainingSeconds == timer.mode.duration ? "开始" : "继续", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Button {
                timer.reset()
            } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                timer.completeCurrentRound()
            } label: {
                Label("完成", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(16)
        .background(.regularMaterial)
    }
}

private enum PomodoroMode: String, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:
            "专注"
        case .shortBreak:
            "短休息"
        case .longBreak:
            "长休息"
        }
    }

    var subtitle: String {
        switch self {
        case .focus:
            "开始一段安静学习"
        case .shortBreak:
            "短暂恢复一下"
        case .longBreak:
            "完成一轮后的长休息"
        }
    }

    var duration: Int {
        switch self {
        case .focus:
            25 * 60
        case .shortBreak:
            5 * 60
        case .longBreak:
            15 * 60
        }
    }

    var systemImage: String {
        switch self {
        case .focus:
            "timer"
        case .shortBreak:
            "cup.and.saucer.fill"
        case .longBreak:
            "figure.cooldown"
        }
    }

    var tint: Color {
        switch self {
        case .focus:
            .blue
        case .shortBreak:
            .green
        case .longBreak:
            .orange
        }
    }
}

@MainActor
private final class PomodoroTimer: ObservableObject {
    @Published var mode: PomodoroMode = .focus {
        didSet {
            if oldValue != mode, !isRunning {
                remainingSeconds = mode.duration
            }
        }
    }
    @Published private(set) var remainingSeconds = PomodoroMode.focus.duration
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusCount = 0

    private var timer: Timer?
    var onRoundFinished: (() -> Void)?

    var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard mode.duration > 0 else { return 1 }
        return 1 - Double(remainingSeconds) / Double(mode.duration)
    }

    var statusTitle: String {
        if isRunning {
            return mode == .focus ? "专注中" : "休息中"
        }
        if remainingSeconds < mode.duration {
            return "已暂停"
        }
        return mode == .focus ? "准备专注" : "准备休息"
    }

    var progressHint: String {
        if mode == .focus {
            return "完成一次专注后，会计入今日番茄次数。"
        }
        return "休息结束后，可以回到专注模式。"
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        remainingSeconds = mode.duration
    }

    func completeCurrentRound() {
        completeCurrentRound(isAutomatic: false)
    }

    private func completeCurrentRound(isAutomatic: Bool) {
        if isAutomatic {
            onRoundFinished?()
        }

        if mode == .focus {
            completedFocusCount += 1
            mode = completedFocusCount % 4 == 0 ? .longBreak : .shortBreak
        } else {
            mode = .focus
        }
        pause()
        remainingSeconds = mode.duration
    }

    private func tick() {
        guard isRunning else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            completeCurrentRound(isAutomatic: true)
        }
    }
}

private enum FocusSoundScene: String, CaseIterable, Identifiable {
    case softRain
    case brownNoise
    case stream

    var id: String { rawValue }

    var title: String {
        switch self {
        case .softRain:
            "雨声"
        case .brownNoise:
            "低噪"
        case .stream:
            "溪流"
        }
    }
}

@MainActor
private final class FocusSoundPlayer: ObservableObject {
    @Published private(set) var isNoiseEnabled = false
    @Published private(set) var scene: FocusSoundScene = .softRain
    @Published private(set) var volume = 0.16

    private let engine = AVAudioEngine()
    private let generator: FocusNoiseGenerator
    private let sourceNode: AVAudioSourceNode

    init() {
        let generator = FocusNoiseGenerator()
        self.generator = generator
        self.sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList in
            generator.render(frameCount: frameCount, audioBufferList: audioBufferList)
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = Float(volume)
    }

    func setNoiseEnabled(_ enabled: Bool) {
        enabled ? startNoise() : stopNoise()
    }

    func selectScene(_ scene: FocusSoundScene) {
        self.scene = scene
        generator.scene = scene
    }

    func setVolume(_ volume: Double) {
        self.volume = volume
        engine.mainMixerNode.outputVolume = Float(volume)
    }

    func startNoise() {
        guard isNoiseEnabled == false else { return }
        generator.scene = scene
        engine.mainMixerNode.outputVolume = Float(volume)

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isNoiseEnabled = true
        } catch {
            isNoiseEnabled = false
        }
    }

    func stopNoise() {
        guard isNoiseEnabled else { return }
        engine.stop()
        isNoiseEnabled = false
    }

    func playCompletionBell() {
        AudioServicesPlaySystemSound(1057)
    }
}

private final class FocusNoiseGenerator {
    var scene: FocusSoundScene = .softRain

    private var seed: UInt64 = 0x1234_5678_ABCD_EF01
    private var brownValue: Float = 0
    private var streamPhase: Float = 0

    func render(frameCount: AVAudioFrameCount, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

        for frame in 0..<Int(frameCount) {
            let sample = nextSample()

            for buffer in buffers {
                guard let data = buffer.mData else { continue }
                let pointer = data.assumingMemoryBound(to: Float.self)
                pointer[frame] = sample
            }
        }

        return noErr
    }

    private func nextSample() -> Float {
        switch scene {
        case .softRain:
            let base = randomFloat() * 0.07
            let drops = randomFloat() > 0.988 ? randomFloat() * 0.2 : 0
            return base + drops
        case .brownNoise:
            brownValue = (brownValue + 0.025 * randomFloat()) / 1.025
            brownValue = min(max(brownValue, -0.24), 0.24)
            return brownValue * 0.75
        case .stream:
            streamPhase += 0.015
            if streamPhase > Float.pi * 2 {
                streamPhase -= Float.pi * 2
            }
            return randomFloat() * 0.045 + sin(streamPhase) * 0.018
        }
    }

    private func randomFloat() -> Float {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1
        let value = Float((seed >> 33) & 0xFFFF) / Float(0xFFFF)
        return value * 2 - 1
    }
}

private struct PomodoroMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct PomodoroTip: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline.weight(.medium))

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        PomodoroTimerView()
    }
}
