import AVFoundation
import SwiftUI
import Vision

struct JumpRopeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = JumpRopeSession()
    @StateObject private var cameraCounter = JumpRopeCameraCounter()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        statusCard
                        cameraCard
                        counterCard
                        targetCard
                        rhythmTips
                    }
                    .padding(20)
                    .padding(.bottom, 18)
                }

                controls
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("跳绳")
            .onAppear {
                cameraCounter.onJumpDetected = { event in
                    session.recordDetectedJump(event)
                }
            }
            .onDisappear {
                cameraCounter.stop()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        cameraCounter.stop()
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: session.isRunning ? "figure.jumprope" : "sparkles")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 42, height: 42)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.statusTitle)
                    .font(.headline)
                Text("给小羽用的轻量跳绳训练")
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
                Text("摄像头计数")
                    .font(.headline)

                Spacer()

                Text(cameraCounter.cameraStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(cameraCounter.isReady ? .orange : .secondary)
            }

            CameraPreviewView(session: cameraCounter.captureSession)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomLeading) {
                    Text(cameraCounter.poseHint)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
                        .padding(10)
                }

            Text("请把 iPhone / iPad 放在正前方，让全身尽量进入画面。小悟会根据人体上下运动自动计数。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("儿童和成人都可以使用。跳跃高度为摄像头估算值，适合观察训练趋势。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var counterCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前次数")
                        .font(.headline)
                    Text("\(session.jumpCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.elapsedText)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                }
            }

            ProgressView(value: session.progress)
                .tint(.orange)

            HStack(spacing: 10) {
                JumpRopeMetric(title: "最近跳高", value: session.lastJumpHeightText)
                JumpRopeMetric(title: "平均跳高", value: session.averageJumpHeightText)
                JumpRopeMetric(title: "最高跳高", value: session.maxJumpHeightText)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("今日目标")
                .font(.headline)

            HStack(spacing: 10) {
                JumpRopeMetric(title: "目标", value: "\(session.targetCount) 次")
                JumpRopeMetric(title: "组数", value: "\(session.setCount) 组")
                JumpRopeMetric(title: "节奏", value: session.rhythmText)
            }

            Stepper("目标 \(session.targetCount) 次", value: $session.targetCount, in: 20...1_000, step: 20)
                .font(.subheadline)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var rhythmTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("小羽提示")
                .font(.headline)

            JumpRopeTip(title: "先稳住", text: "前 30 秒不用追求速度，先保持连续。")
            JumpRopeTip(title: "小目标", text: "每完成 50 次休息一下，慢慢增加总量。")
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if session.isRunning {
                Button {
                    if session.isPaused {
                        session.resume()
                        cameraCounter.resumeCounting()
                    } else {
                        session.pause()
                        cameraCounter.pauseCounting()
                    }
                } label: {
                    Label(session.isPaused ? "继续" : "暂停", systemImage: session.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    session.finish()
                    cameraCounter.stop()
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button {
                    session.start()
                    cameraCounter.start()
                } label: {
                    Label("打开摄像头", systemImage: "camera.fill")
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

@MainActor
private final class JumpRopeSession: ObservableObject {
    @Published var targetCount = 100
    @Published private(set) var jumpCount = 0
    @Published private(set) var setCount = 0
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var lastJumpHeight: Double = 0
    @Published private(set) var totalJumpHeight: Double = 0
    @Published private(set) var maxJumpHeight: Double = 0

    private var timer: Timer?
    private var startedAt: Date?
    private var pausedAt: Date?
    private var pausedDuration: TimeInterval = 0

    var elapsedText: String {
        Formatters.stopwatch(elapsedTime)
    }

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(jumpCount) / Double(targetCount), 1)
    }

    var rhythmText: String {
        guard elapsedTime > 0 else { return "--" }
        let perMinute = Double(jumpCount) / elapsedTime * 60
        return "\(Int(perMinute.rounded())) /分"
    }

    var lastJumpHeightText: String {
        jumpHeightText(lastJumpHeight)
    }

    var averageJumpHeightText: String {
        guard jumpCount > 0 else { return "--" }
        return jumpHeightText(totalJumpHeight / Double(jumpCount))
    }

    var maxJumpHeightText: String {
        jumpHeightText(maxJumpHeight)
    }

    var statusTitle: String {
        if isPaused { return "休息一下" }
        if isRunning { return "正在跳绳" }
        return "准备开始"
    }

    func start() {
        jumpCount = 0
        setCount = 0
        elapsedTime = 0
        lastJumpHeight = 0
        totalJumpHeight = 0
        maxJumpHeight = 0
        pausedDuration = 0
        startedAt = Date()
        pausedAt = nil
        isRunning = true
        isPaused = false
        startTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pausedAt = Date()
        timer?.invalidate()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        if let pausedAt {
            pausedDuration += Date().timeIntervalSince(pausedAt)
        }
        pausedAt = nil
        isPaused = false
        startTimer()
    }

    func finish() {
        isRunning = false
        isPaused = false
        startedAt = nil
        pausedAt = nil
        timer?.invalidate()
        timer = nil
    }

    func recordDetectedJump(_ event: JumpRopeEvent) {
        guard isRunning, !isPaused, event.confidence >= 0.35 else { return }
        jumpCount += 1
        setCount = max(1, Int(ceil(Double(jumpCount) / 50.0)))
        lastJumpHeight = event.estimatedHeightCentimeters
        totalJumpHeight += event.estimatedHeightCentimeters
        maxJumpHeight = max(maxJumpHeight, event.estimatedHeightCentimeters)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard let startedAt, isRunning, !isPaused else { return }
        elapsedTime = Date().timeIntervalSince(startedAt) - pausedDuration
    }

    private func jumpHeightText(_ value: Double) -> String {
        guard value > 0 else { return "--" }
        return "\(Int(value.rounded())) cm"
    }
}

private struct JumpRopeEvent {
    let confidence: Double
    let estimatedHeightCentimeters: Double
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private final class JumpRopeCameraCounter: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var cameraStatus = "未开启"
    @Published private(set) var poseHint = "准备打开摄像头"
    @Published private(set) var isReady = false

    let captureSession = AVCaptureSession()
    var onJumpDetected: ((JumpRopeEvent) -> Void)?

    private let sessionQueue = DispatchQueue(label: "xiaowuOS.jumpRope.camera")
    private let visionQueue = DispatchQueue(label: "xiaowuOS.jumpRope.vision")
    private let videoOutput = AVCaptureVideoDataOutput()

    private var isConfigured = false
    private var isProcessingFrame = false
    private var isCountingEnabled = false
    private var smoothedY: CGFloat?
    private var lowY: CGFloat?
    private var highY: CGFloat?
    private var isJumpCandidate = false
    private var lastJumpAt = Date.distantPast
    private var lastProcessedFrameAt = Date.distantPast
    private let minimumFrameInterval: TimeInterval = 0.08

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
            setStatus("等待授权", hint: "请允许使用摄像头", ready: false)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                granted ? self?.configureAndStart() : self?.setStatus("未授权", hint: "请在系统设置中允许摄像头", ready: false)
            }
        case .denied, .restricted:
            setStatus("未授权", hint: "请在系统设置中允许摄像头", ready: false)
        @unknown default:
            setStatus("不可用", hint: "当前设备摄像头不可用", ready: false)
        }
    }

    func pauseCounting() {
        isCountingEnabled = false
        setStatus("已暂停", hint: "继续后恢复自动计数", ready: true)
    }

    func resumeCounting() {
        isCountingEnabled = true
        resetMotionState()
        setStatus("识别中", hint: "保持全身入镜", ready: true)
    }

    func stop() {
        isCountingEnabled = false
        resetMotionState()
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.isProcessingFrame = false
            self.lastProcessedFrameAt = .distantPast
            self.setStatus("未开启", hint: "准备打开摄像头", ready: false)
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.isConfigured == false {
                self.configureSession()
            }

            guard self.isConfigured else { return }
            self.isCountingEnabled = true
            self.resetMotionState()

            if self.captureSession.isRunning == false {
                self.captureSession.startRunning()
            }
            self.setStatus("识别中", hint: "保持全身入镜", ready: true)
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
            setStatus("不可用", hint: "没有找到前置摄像头", ready: false)
            return
        }

        captureSession.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard captureSession.canAddOutput(videoOutput) else {
            setStatus("不可用", hint: "摄像头输出不可用", ready: false)
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
        guard isCountingEnabled,
              isProcessingFrame == false,
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
              let bodyCenter = bodyCenterY(from: observation) else {
            setStatus("识别中", hint: "请退后一点，让上半身入镜", ready: true)
            return
        }

        detectJump(with: bodyCenter.y, bodyHeight: bodyCenter.bodyHeight, confidence: bodyCenter.confidence)
    }

    private func bodyCenterY(from observation: VNHumanBodyPoseObservation) -> (y: CGFloat, bodyHeight: CGFloat, confidence: Double)? {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return nil
        }

        let weightedJointNames: [(VNHumanBodyPoseObservation.JointName, CGFloat)] = [
            (.root, 0.45),
            (.leftHip, 0.18),
            (.rightHip, 0.18),
            (.neck, 0.10),
            (.leftShoulder, 0.045),
            (.rightShoulder, 0.045)
        ]

        let weightedPoints = weightedJointNames.compactMap { name, weight -> (point: VNRecognizedPoint, weight: CGFloat)? in
            guard let point = recognizedPoints[name], point.confidence > 0.30 else {
                return nil
            }
            return (point, weight)
        }

        guard weightedPoints.count >= 2 else {
            return nil
        }

        let totalWeight = weightedPoints.map(\.weight).reduce(0, +)
        let averageY = weightedPoints.reduce(CGFloat.zero) { partial, item in
            partial + item.point.location.y * item.weight
        } / max(totalWeight, 0.01)
        let confidence = weightedPoints.map { Double($0.point.confidence) }.reduce(0, +) / Double(weightedPoints.count)
        let bodyHeight = estimatedBodyHeight(from: recognizedPoints)
        return (averageY, bodyHeight, confidence)
    }

    private func estimatedBodyHeight(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> CGFloat {
        let reliablePoints = points.values.filter { $0.confidence > 0.35 }
        guard let minY = reliablePoints.map(\.location.y).min(),
              let maxY = reliablePoints.map(\.location.y).max() else {
            return 0.35
        }
        return max(maxY - minY, 0.28)
    }

    private func detectJump(with bodyY: CGFloat, bodyHeight: CGFloat, confidence: Double) {
        let smoothing: CGFloat = 0.45
        let currentY: CGFloat

        if let smoothedY {
            currentY = smoothedY * (1 - smoothing) + bodyY * smoothing
        } else {
            currentY = bodyY
        }
        self.smoothedY = currentY

        if lowY == nil || highY == nil {
            lowY = currentY
            highY = currentY
            setStatus("校准中", hint: "先连续跳几下，小悟会自动适应幅度", ready: true)
            return
        }

        guard var lowY, var highY else { return }
        lowY = min(lowY * 0.97 + currentY * 0.03, currentY)
        highY = max(highY * 0.97 + currentY * 0.03, currentY)
        self.lowY = lowY
        self.highY = highY

        let range = max(highY - lowY, 0.012)
        let normalizedLift = (currentY - lowY) / range
        let now = Date()
        let minimumInterval: TimeInterval = 0.16
        let takeoffThreshold: CGFloat = 0.42
        let landingThreshold: CGFloat = 0.20
        let enoughMovement = range > 0.010 || normalizedLift > 0.55

        if !isJumpCandidate,
           enoughMovement,
           normalizedLift >= takeoffThreshold,
           now.timeIntervalSince(lastJumpAt) > minimumInterval {
            isJumpCandidate = true
            lastJumpAt = now
            let estimatedHeight = estimatedJumpHeightCentimeters(lift: max(range * normalizedLift, 0.010), bodyHeight: bodyHeight)
            setStatus("识别中", hint: "跳高约 \(Int(estimatedHeight.rounded())) cm", ready: true)
            DispatchQueue.main.async { [weak self] in
                self?.onJumpDetected?(JumpRopeEvent(confidence: confidence, estimatedHeightCentimeters: estimatedHeight))
            }
        } else if isJumpCandidate, normalizedLift <= landingThreshold {
            isJumpCandidate = false
        }
    }

    private func estimatedJumpHeightCentimeters(lift: CGFloat, bodyHeight: CGFloat) -> Double {
        let bodyHeightCentimeters: CGFloat = 150
        let centimeters = lift / max(bodyHeight, 0.28) * bodyHeightCentimeters
        return min(max(Double(centimeters), 2), 45)
    }

    private func resetMotionState() {
        smoothedY = nil
        lowY = nil
        highY = nil
        isJumpCandidate = false
        lastJumpAt = .distantPast
    }

    private func finishFrameProcessing() {
        isProcessingFrame = false
    }

    private func setStatus(_ status: String, hint: String, ready: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.cameraStatus = status
            self?.poseHint = hint
            self?.isReady = ready
        }
    }
}

private struct JumpRopeMetric: View {
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

private struct JumpRopeTip: View {
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
    JumpRopeView()
}
