import AVFoundation
import SwiftUI
import Vision

struct WubuquanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = WubuquanSession()
    @StateObject private var coach = WubuquanCameraCoach()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        statusCard
                        cameraCard
                        scoreCard
                        stepsCard
                        tipsCard
                    }
                    .padding(20)
                    .padding(.bottom, 18)
                }

                controls
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("五步拳")
            .onAppear {
                coach.onFeedback = { feedback in
                    session.receive(feedback)
                }
            }
            .onDisappear {
                coach.stop()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        coach.stop()
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.martial.arts")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 42, height: 42)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.statusTitle)
                    .font(.headline)

                Text("当前动作：\(session.currentStep.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var cameraCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("动作指导")
                    .font(.headline)

                Spacer()

                Text(coach.cameraStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(coach.isReady ? .orange : .secondary)
            }

            WubuquanCameraPreview(session: coach.captureSession)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    WubuquanDemoPipView(step: session.currentStep)
                        .frame(width: 128, height: 150)
                        .padding(10)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(session.liveHint)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
                        .padding(10)
                }

            Text(session.currentStep.cue)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("实时分数")
                        .font(.headline)

                    Text("\(session.currentScore)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("总评")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(session.gradeText)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            ProgressView(value: session.progress)
                .tint(.orange)

            HStack(spacing: 10) {
                WubuquanMetric(title: "稳定", value: "\(session.stabilityScore)")
                WubuquanMetric(title: "完成", value: "\(session.completedCount) / \(WubuquanStep.allCases.count)")
                WubuquanMetric(title: "最好", value: "\(session.bestScore)")
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("动作流程")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(WubuquanStep.allCases) { step in
                    WubuquanStepLine(
                        step: step,
                        isCurrent: step == session.currentStep,
                        isDone: session.completedSteps.contains(step)
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("练习提示")
                .font(.headline)

            WubuquanTip(title: "先看全身", text: "手机放在正前方，脚、手和上半身尽量都入镜。")
            WubuquanTip(title: "先稳再快", text: "每个动作先停稳，小悟会根据稳定度自动进入下一式。")
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if session.isRunning {
                Button {
                    session.resetCurrentStep()
                } label: {
                    Label("重练本式", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    session.finish()
                    coach.stop()
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    session.start()
                    coach.start()
                } label: {
                    Label("开始五步拳", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(16)
        .background(.regularMaterial)
    }
}

private enum WubuquanStep: String, CaseIterable, Identifiable {
    case bowPunch
    case kickPunch
    case horseBlock
    case crouchStrike
    case kneePalm
    case emptyPalm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bowPunch:
            "弓步冲拳"
        case .kickPunch:
            "弹腿冲拳"
        case .horseBlock:
            "马步架打"
        case .crouchStrike:
            "歇步盖打"
        case .kneePalm:
            "提膝穿掌"
        case .emptyPalm:
            "虚步挑掌"
        }
    }

    var cue: String {
        switch self {
        case .bowPunch:
            "前腿弯、后腿蹬，冲拳要直。"
        case .kickPunch:
            "弹腿干净，身体不要后仰。"
        case .horseBlock:
            "两脚打开，重心下沉，手臂架稳。"
        case .crouchStrike:
            "身体压低，动作要稳，不要晃。"
        case .kneePalm:
            "膝盖提起，掌向前穿，身体立住。"
        case .emptyPalm:
            "前脚轻点，重心在后，挑掌到位。"
        }
    }

    var systemImage: String {
        switch self {
        case .bowPunch:
            "figure.strengthtraining.traditional"
        case .kickPunch:
            "figure.kickboxing"
        case .horseBlock:
            "figure.martial.arts"
        case .crouchStrike:
            "figure.core.training"
        case .kneePalm:
            "figure.highintensity.intervaltraining"
        case .emptyPalm:
            "figure.cooldown"
        }
    }
}

@MainActor
private final class WubuquanSession: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var currentStep: WubuquanStep = .bowPunch
    @Published private(set) var currentScore = 0
    @Published private(set) var stabilityScore = 0
    @Published private(set) var bestScore = 0
    @Published private(set) var completedSteps: Set<WubuquanStep> = []
    @Published private(set) var liveHint = "把全身放进画面"

    private var stableFrames = 0

    var completedCount: Int {
        completedSteps.count
    }

    var progress: Double {
        Double(completedSteps.count) / Double(WubuquanStep.allCases.count)
    }

    var statusTitle: String {
        if isRunning == false { return "准备练习" }
        if completedSteps.count == WubuquanStep.allCases.count { return "本轮完成" }
        return "跟练中"
    }

    var gradeText: String {
        if bestScore >= 90 { return "优秀" }
        if bestScore >= 75 { return "良好" }
        if bestScore >= 60 { return "继续" }
        return "校准中"
    }

    func start() {
        isRunning = true
        currentStep = .bowPunch
        currentScore = 0
        stabilityScore = 0
        bestScore = 0
        completedSteps = []
        stableFrames = 0
        liveHint = currentStep.cue
    }

    func finish() {
        isRunning = false
        stableFrames = 0
    }

    func resetCurrentStep() {
        stableFrames = 0
        currentScore = 0
        stabilityScore = 0
        liveHint = currentStep.cue
    }

    func receive(_ feedback: WubuquanFeedback) {
        guard isRunning else { return }
        currentScore = feedback.score
        stabilityScore = feedback.stability
        bestScore = max(bestScore, feedback.score)
        liveHint = feedback.hint

        if feedback.score >= 72, feedback.stability >= 65 {
            stableFrames += 1
        } else {
            stableFrames = max(0, stableFrames - 1)
        }

        if stableFrames >= 12 {
            completeCurrentStep()
        }
    }

    private func completeCurrentStep() {
        completedSteps.insert(currentStep)
        stableFrames = 0

        guard let currentIndex = WubuquanStep.allCases.firstIndex(of: currentStep),
              currentIndex + 1 < WubuquanStep.allCases.count else {
            liveHint = "本轮五步拳完成"
            return
        }

        currentStep = WubuquanStep.allCases[currentIndex + 1]
        liveHint = currentStep.cue
    }
}

private struct WubuquanFeedback {
    let score: Int
    let stability: Int
    let hint: String
}

private struct WubuquanCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> WubuquanPreviewView {
        let view = WubuquanPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: WubuquanPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class WubuquanPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private final class WubuquanCameraCoach: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var cameraStatus = "未开启"
    @Published private(set) var isReady = false

    let captureSession = AVCaptureSession()
    var onFeedback: ((WubuquanFeedback) -> Void)?

    private let sessionQueue = DispatchQueue(label: "xiaowuOS.wubuquan.camera")
    private let visionQueue = DispatchQueue(label: "xiaowuOS.wubuquan.vision")
    private let videoOutput = AVCaptureVideoDataOutput()

    private var isConfigured = false
    private var isProcessingFrame = false
    private var lastProcessedFrameAt = Date.distantPast
    private let minimumFrameInterval: TimeInterval = 0.15
    private var lastCenterX: CGFloat?
    private var lastCenterY: CGFloat?

    deinit {
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            setStatus("等待授权", ready: false)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                granted ? self?.configureAndStart() : self?.setStatus("未授权", ready: false)
            }
        case .denied, .restricted:
            setStatus("未授权", ready: false)
        @unknown default:
            setStatus("不可用", ready: false)
        }
    }

    func stop() {
        resetMotion()
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.isProcessingFrame = false
            self.lastProcessedFrameAt = .distantPast
            self.setStatus("未开启", ready: false)
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.isConfigured == false {
                self.configureSession()
            }

            guard self.isConfigured else { return }
            self.resetMotion()

            if self.captureSession.isRunning == false {
                self.captureSession.startRunning()
            }
            self.setStatus("识别中", ready: true)
        }
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .low

        defer {
            captureSession.commitConfiguration()
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else {
            setStatus("不可用", ready: false)
            return
        }

        captureSession.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard captureSession.canAddOutput(videoOutput) else {
            setStatus("不可用", ready: false)
            return
        }

        captureSession.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        isConfigured = true
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        guard isProcessingFrame == false,
              now.timeIntervalSince(lastProcessedFrameAt) >= minimumFrameInterval else { return }

        lastProcessedFrameAt = now
        isProcessingFrame = true

        autoreleasepool {
            let request = VNDetectHumanBodyPoseRequest { [weak self] request, _ in
                self?.handlePoseResult(request)
            }

            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored)
            do {
                try handler.perform([request])
            } catch {
                finishFrameProcessing()
            }
        }
    }

    private func handlePoseResult(_ request: VNRequest) {
        defer { finishFrameProcessing() }

        guard let observation = request.results?.first as? VNHumanBodyPoseObservation,
              let metrics = poseMetrics(from: observation) else {
            publish(WubuquanFeedback(score: 0, stability: 0, hint: "请退后一点，让全身入镜"))
            return
        }

        publish(score(metrics))
    }

    private func poseMetrics(from observation: VNHumanBodyPoseObservation) -> WubuquanPoseMetrics? {
        guard let points = try? observation.recognizedPoints(.all) else {
            return nil
        }

        func point(_ name: VNHumanBodyPoseObservation.JointName) -> VNRecognizedPoint? {
            guard let value = points[name], value.confidence > 0.25 else { return nil }
            return value
        }

        guard let neck = point(.neck),
              let root = point(.root),
              let leftShoulder = point(.leftShoulder),
              let rightShoulder = point(.rightShoulder),
              let leftHip = point(.leftHip),
              let rightHip = point(.rightHip) else {
            return nil
        }

        let leftAnkle = point(.leftAnkle)
        let rightAnkle = point(.rightAnkle)
        let leftWrist = point(.leftWrist)
        let rightWrist = point(.rightWrist)
        let leftKnee = point(.leftKnee)
        let rightKnee = point(.rightKnee)

        let reliable = points.values.filter { $0.confidence > 0.25 }
        let width = max((reliable.map(\.location.x).max() ?? 0) - (reliable.map(\.location.x).min() ?? 0), 0.1)
        let height = max((reliable.map(\.location.y).max() ?? 0) - (reliable.map(\.location.y).min() ?? 0), 0.25)
        let centerX = (neck.location.x + root.location.x) / 2
        let centerY = (neck.location.y + root.location.y) / 2

        let shoulderLevel = 1 - min(abs(leftShoulder.location.y - rightShoulder.location.y) * 7, 1)
        let hipLevel = 1 - min(abs(leftHip.location.y - rightHip.location.y) * 7, 1)
        let stanceWidth = normalizedDistance(leftAnkle, rightAnkle, fallback: width, bodyHeight: height)
        let armExtension = max(
            normalizedDistance(leftWrist, rightShoulder, fallback: 0, bodyHeight: height),
            normalizedDistance(rightWrist, leftShoulder, fallback: 0, bodyHeight: height)
        )
        let kneeLift = max(
            normalizedVerticalLift(leftKnee, root, bodyHeight: height),
            normalizedVerticalLift(rightKnee, root, bodyHeight: height)
        )
        let crouch = 1 - min(max((root.location.y - (leftAnkle?.location.y ?? root.location.y)) / height, 0), 1)

        let movement: CGFloat
        if let lastCenterX, let lastCenterY {
            movement = abs(centerX - lastCenterX) + abs(centerY - lastCenterY)
        } else {
            movement = 0
        }
        lastCenterX = centerX
        lastCenterY = centerY

        return WubuquanPoseMetrics(
            shoulderLevel: shoulderLevel,
            hipLevel: hipLevel,
            stanceWidth: stanceWidth,
            armExtension: armExtension,
            kneeLift: kneeLift,
            crouch: crouch,
            movement: movement
        )
    }

    private func score(_ metrics: WubuquanPoseMetrics) -> WubuquanFeedback {
        let base = metrics.shoulderLevel * 24 + metrics.hipLevel * 18
        let stance = min(metrics.stanceWidth / 0.65, 1) * 20
        let arms = min(metrics.armExtension / 0.55, 1) * 20
        let liftOrLow = max(min(metrics.kneeLift / 0.28, 1), min(metrics.crouch / 0.32, 1)) * 18
        let score = Int(min(max(base + stance + arms + liftOrLow, 0), 100).rounded())
        let stability = Int(min(max((1 - min(metrics.movement * 18, 1)) * 100, 0), 100).rounded())

        let hint: String
        if metrics.stanceWidth < 0.32 {
            hint = "脚步再打开一点"
        } else if metrics.armExtension < 0.35 {
            hint = "手臂再打出去一点"
        } else if metrics.shoulderLevel < 0.72 {
            hint = "肩膀放平，身体别歪"
        } else if stability < 55 {
            hint = "动作停稳一点"
        } else if score >= 80 {
            hint = "很好，保持 1 秒"
        } else {
            hint = "继续调整动作"
        }

        return WubuquanFeedback(score: score, stability: stability, hint: hint)
    }

    private func normalizedDistance(_ first: VNRecognizedPoint?, _ second: VNRecognizedPoint?, fallback: CGFloat, bodyHeight: CGFloat) -> CGFloat {
        guard let first, let second else { return fallback }
        let dx = first.location.x - second.location.x
        let dy = first.location.y - second.location.y
        return sqrt(dx * dx + dy * dy) / max(bodyHeight, 0.25)
    }

    private func normalizedVerticalLift(_ first: VNRecognizedPoint?, _ second: VNRecognizedPoint?, bodyHeight: CGFloat) -> CGFloat {
        guard let first, let second else { return 0 }
        return max(first.location.y - second.location.y, 0) / max(bodyHeight, 0.25)
    }

    private func resetMotion() {
        lastCenterX = nil
        lastCenterY = nil
    }

    private func finishFrameProcessing() {
        isProcessingFrame = false
    }

    private func setStatus(_ status: String, ready: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.cameraStatus = status
            self?.isReady = ready
        }
    }

    private func publish(_ feedback: WubuquanFeedback) {
        DispatchQueue.main.async { [weak self] in
            self?.onFeedback?(feedback)
        }
    }
}

private struct WubuquanPoseMetrics {
    let shoulderLevel: CGFloat
    let hipLevel: CGFloat
    let stanceWidth: CGFloat
    let armExtension: CGFloat
    let kneeLift: CGFloat
    let crouch: CGFloat
    let movement: CGFloat
}

private struct WubuquanMetric: View {
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

private struct WubuquanStepLine: View {
    let step: WubuquanStep
    let isCurrent: Bool
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isDone ? "checkmark.circle.fill" : step.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(isCurrent || isDone ? .orange : .secondary)
                .frame(width: 30, height: 30)
                .background((isCurrent || isDone ? Color.orange : Color.gray).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.subheadline.weight(.medium))

                Text(step.cue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct WubuquanTip: View {
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

private struct WubuquanDemoPipView: View {
    let step: WubuquanStep

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("示范")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(step.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            TimelineView(.periodic(from: .now, by: 1.0 / 12.0)) { timeline in
                let phase = demoPhase(for: timeline.date)
                WubuquanDemoFigure(step: step, phase: phase)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.38), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }

    private func demoPhase(for date: Date) -> Double {
        let loop = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8
        return 0.5 - 0.5 * cos(loop * .pi * 2)
    }
}

private struct WubuquanDemoFigure: View {
    let step: WubuquanStep
    let phase: Double

    var body: some View {
        Canvas { context, size in
            let pose = DemoPose(step: step, phase: phase, size: size)
            var stroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            let bodyColor = Color.primary.opacity(0.72)
            let accentColor = Color.orange

            drawLine(&context, from: pose.head, to: pose.body, color: bodyColor, stroke: stroke)
            drawLine(&context, from: pose.body, to: pose.leftHand, color: accentColor, stroke: stroke)
            drawLine(&context, from: pose.body, to: pose.rightHand, color: accentColor, stroke: stroke)
            drawLine(&context, from: pose.body, to: pose.leftFoot, color: bodyColor, stroke: stroke)
            drawLine(&context, from: pose.body, to: pose.rightFoot, color: bodyColor, stroke: stroke)

            stroke.lineWidth = 3
            drawLine(&context, from: pose.leftFoot, to: pose.rightFoot, color: Color.secondary.opacity(0.22), stroke: stroke)

            context.fill(
                Path(ellipseIn: CGRect(x: pose.head.x - 10, y: pose.head.y - 10, width: 20, height: 20)),
                with: .color(Color.primary.opacity(0.72))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: pose.leftHand.x - 5, y: pose.leftHand.y - 5, width: 10, height: 10)),
                with: .color(accentColor)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: pose.rightHand.x - 5, y: pose.rightHand.y - 5, width: 10, height: 10)),
                with: .color(accentColor)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.24), in: RoundedRectangle(cornerRadius: 7))
    }

    private func drawLine(_ context: inout GraphicsContext, from start: CGPoint, to end: CGPoint, color: Color, stroke: StrokeStyle) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), style: stroke)
    }
}

private struct DemoPose {
    let head: CGPoint
    let body: CGPoint
    let leftHand: CGPoint
    let rightHand: CGPoint
    let leftFoot: CGPoint
    let rightFoot: CGPoint

    init(step: WubuquanStep, phase: Double, size: CGSize) {
        let w = size.width
        let h = size.height
        let p = CGFloat(phase)
        let centerX = w * 0.5
        let headY = h * 0.23
        let bodyY = h * (0.50 + Self.motionOffset(for: step, phase: p))
        let body = CGPoint(x: centerX, y: bodyY)
        self.head = CGPoint(x: centerX + Self.headShift(for: step, phase: p) * w, y: headY)
        self.body = body

        switch step {
        case .bowPunch:
            leftFoot = CGPoint(x: w * (0.28 - 0.05 * p), y: h * 0.84)
            rightFoot = CGPoint(x: w * (0.76 + 0.04 * p), y: h * 0.80)
            leftHand = CGPoint(x: w * 0.35, y: h * 0.48)
            rightHand = CGPoint(x: w * (0.58 + 0.28 * p), y: h * (0.44 - 0.04 * p))
        case .kickPunch:
            leftFoot = CGPoint(x: w * 0.30, y: h * 0.84)
            rightFoot = CGPoint(x: w * (0.63 + 0.22 * p), y: h * (0.80 - 0.30 * p))
            leftHand = CGPoint(x: w * 0.34, y: h * 0.48)
            rightHand = CGPoint(x: w * (0.58 + 0.24 * p), y: h * 0.42)
        case .horseBlock:
            leftFoot = CGPoint(x: w * (0.32 - 0.08 * p), y: h * 0.84)
            rightFoot = CGPoint(x: w * (0.68 + 0.08 * p), y: h * 0.84)
            leftHand = CGPoint(x: w * (0.34 - 0.10 * p), y: h * (0.50 - 0.12 * p))
            rightHand = CGPoint(x: w * (0.66 + 0.12 * p), y: h * (0.52 - 0.04 * p))
        case .crouchStrike:
            leftFoot = CGPoint(x: w * 0.35, y: h * 0.86)
            rightFoot = CGPoint(x: w * (0.70 - 0.10 * p), y: h * (0.84 - 0.08 * p))
            leftHand = CGPoint(x: w * 0.36, y: h * (0.48 + 0.16 * p))
            rightHand = CGPoint(x: w * (0.62 + 0.18 * p), y: h * (0.45 + 0.10 * p))
        case .kneePalm:
            leftFoot = CGPoint(x: w * 0.35, y: h * 0.86)
            rightFoot = CGPoint(x: w * (0.64 + 0.04 * p), y: h * (0.82 - 0.34 * p))
            leftHand = CGPoint(x: w * 0.38, y: h * 0.48)
            rightHand = CGPoint(x: w * (0.56 + 0.22 * p), y: h * (0.50 - 0.28 * p))
        case .emptyPalm:
            leftFoot = CGPoint(x: w * 0.38, y: h * 0.86)
            rightFoot = CGPoint(x: w * (0.66 + 0.10 * p), y: h * (0.84 - 0.03 * p))
            leftHand = CGPoint(x: w * 0.38, y: h * 0.52)
            rightHand = CGPoint(x: w * (0.58 + 0.15 * p), y: h * (0.54 - 0.22 * p))
        }
    }

    private static func motionOffset(for step: WubuquanStep, phase: CGFloat) -> CGFloat {
        switch step {
        case .horseBlock, .crouchStrike:
            0.10 * phase
        case .kickPunch, .kneePalm:
            -0.03 * phase
        default:
            0
        }
    }

    private static func headShift(for step: WubuquanStep, phase: CGFloat) -> CGFloat {
        switch step {
        case .bowPunch, .kickPunch:
            0.03 * phase
        case .emptyPalm:
            -0.02 * phase
        default:
            0
        }
    }
}

#Preview {
    WubuquanView()
}
