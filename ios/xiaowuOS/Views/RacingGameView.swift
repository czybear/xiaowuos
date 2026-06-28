import SwiftUI

struct RacingGameView: View {
    @StateObject private var game = RacingGameModel()

    var body: some View {
        VStack(spacing: 0) {
            scoreBar

            RacingRoadView(
                playerLane: game.playerLane,
                items: game.items,
                sceneryOffset: game.sceneryOffset,
                sceneryTheme: game.sceneryTheme,
                isRunning: game.isRunning,
                isGameOver: game.isGameOver,
                onTouch: { x, width in
                    game.handleTouch(x: x, width: width)
                }
            )
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            controls
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("赛车")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            game.pause()
        }
    }

    private var scoreBar: some View {
        HStack(spacing: 10) {
            RacingStat(title: "得分", value: "\(game.score)")
            RacingStat(title: "路程", value: "\(game.distance)m")
            RacingStat(title: "生命", value: String(repeating: "♥", count: max(game.lives, 0)))
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if game.isGameOver {
                Text("完成 \(game.distance)m")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    game.moveLeft()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(game.isRunning == false)

                Button {
                    game.isRunning ? game.pause() : game.start()
                } label: {
                    Label(game.primaryActionTitle, systemImage: game.primaryActionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    game.moveRight()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(game.isRunning == false)
            }

            Text("也可以直接按住赛道左右滑动控制赛车")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                game.reset()
            } label: {
                Label("重新开始", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(18)
        .background(.regularMaterial)
    }
}

@MainActor
private final class RacingGameModel: ObservableObject {
    @Published private(set) var playerLane = 1
    @Published private(set) var score = 0
    @Published private(set) var distance = 0
    @Published private(set) var lives = 3
    @Published private(set) var isRunning = false
    @Published private(set) var isGameOver = false
    @Published private(set) var items: [RacingItem] = []
    @Published private(set) var sceneryOffset: CGFloat = 0
    @Published private(set) var sceneryTheme: RacingSceneryTheme = .meadow

    private var timer: Timer?
    private var spawnTicks = 0
    private var tickCount = 0

    var primaryActionTitle: String {
        if isGameOver { return "再玩一次" }
        return isRunning ? "暂停" : "开始"
    }

    var primaryActionIcon: String {
        if isGameOver { return "play.fill" }
        return isRunning ? "pause.fill" : "play.fill"
    }

    func start() {
        if isGameOver {
            reset()
        }

        guard isRunning == false else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
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
        playerLane = 1
        score = 0
        distance = 0
        lives = 3
        isGameOver = false
        items = []
        sceneryOffset = 0
        sceneryTheme = .meadow
        spawnTicks = 0
        tickCount = 0
    }

    func moveLeft() {
        guard isRunning else { return }
        playerLane = max(playerLane - 1, 0)
    }

    func moveRight() {
        guard isRunning else { return }
        playerLane = min(playerLane + 1, 2)
    }

    func handleTouch(x: CGFloat, width: CGFloat) {
        if isRunning == false, isGameOver == false {
            start()
        }
        guard isRunning else { return }

        let sideWidth = width * 0.15
        let roadWidth = width - sideWidth * 2
        let laneWidth = roadWidth / 3
        let lane = Int(((x - sideWidth) / laneWidth).rounded(.down))
        playerLane = min(max(lane, 0), 2)
    }

    private func tick() {
        guard isRunning else { return }

        tickCount += 1
        if tickCount % 6 == 0 {
            distance += 1
        }

        let speed = 0.010 + min(CGFloat(distance), 500) * 0.000012
        sceneryOffset = (sceneryOffset + speed * 1.35).truncatingRemainder(dividingBy: 1)
        sceneryTheme = RacingSceneryTheme.theme(for: distance)
        items = items.map { item in
            var updated = item
            updated.y += speed
            return updated
        }

        handleCollisions()
        removePassedItems()
        spawnIfNeeded()
    }

    private func handleCollisions() {
        var remaining: [RacingItem] = []

        for item in items {
            let hitZone = item.y > 0.76 && item.y < 0.93
            if hitZone, item.lane == playerLane {
                switch item.kind {
                case .star:
                    score += 10
                case .cone:
                    lives -= 1
                    if lives <= 0 {
                        endGame()
                    }
                }
            } else {
                remaining.append(item)
            }
        }

        items = remaining
    }

    private func removePassedItems() {
        var remaining: [RacingItem] = []

        for item in items {
            if item.y > 1.08 {
                if item.kind == .cone {
                    score += 1
                }
            } else {
                remaining.append(item)
            }
        }

        items = remaining
    }

    private func spawnIfNeeded() {
        guard isGameOver == false else { return }

        spawnTicks -= 1
        guard spawnTicks <= 0 else { return }

        let lane = Int.random(in: 0...2)
        let kind: RacingItem.Kind = Int.random(in: 0...4) == 0 ? .star : .cone
        items.append(RacingItem(lane: lane, y: -0.10, kind: kind))
        spawnTicks = max(12, 30 - min(distance / 25, 12))
    }

    private func endGame() {
        isGameOver = true
        pause()
    }
}

private struct RacingItem: Identifiable {
    enum Kind {
        case cone
        case star
    }

    let id = UUID()
    let lane: Int
    var y: CGFloat
    let kind: Kind
}

private enum RacingSceneryTheme: CaseIterable {
    case meadow
    case lake
    case hills

    static func theme(for distance: Int) -> RacingSceneryTheme {
        let index = (distance / 80) % allCases.count
        return allCases[index]
    }

    var skyTop: Color {
        switch self {
        case .meadow: Color(red: 0.45, green: 0.72, blue: 0.98)
        case .lake: Color(red: 0.35, green: 0.66, blue: 0.96)
        case .hills: Color(red: 0.68, green: 0.78, blue: 0.95)
        }
    }

    var ground: Color {
        switch self {
        case .meadow: Color(red: 0.28, green: 0.62, blue: 0.30)
        case .lake: Color(red: 0.23, green: 0.56, blue: 0.68)
        case .hills: Color(red: 0.38, green: 0.58, blue: 0.34)
        }
    }
}

private struct RacingRoadView: View {
    let playerLane: Int
    let items: [RacingItem]
    let sceneryOffset: CGFloat
    let sceneryTheme: RacingSceneryTheme
    let isRunning: Bool
    let isGameOver: Bool
    let onTouch: (CGFloat, CGFloat) -> Void

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let roadRect = roadRect(in: size)
                drawScenery(in: &context, size: size, roadRect: roadRect)
                drawRoad(in: &context, size: size, roadRect: roadRect)
                drawItems(in: &context, size: size, roadRect: roadRect)
                drawPlayer(in: &context, size: size, roadRect: roadRect)

                if isGameOver {
                    drawGameOver(in: &context, size: size)
                } else if isRunning == false {
                    drawStartHint(in: &context, size: size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onTouch(value.location.x, geometry.size.width)
                    }
            )
        }
        .aspectRatio(0.72, contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func roadRect(in size: CGSize) -> CGRect {
        let sideWidth = size.width * 0.15
        return CGRect(x: sideWidth, y: 0, width: size.width - sideWidth * 2, height: size.height)
    }

    private func drawScenery(in context: inout GraphicsContext, size: CGSize, roadRect: CGRect) {
        let full = CGRect(origin: .zero, size: size)
        context.fill(Path(full), with: .linearGradient(
            Gradient(colors: [sceneryTheme.skyTop, sceneryTheme.ground]),
            startPoint: CGPoint(x: size.width * 0.5, y: 0),
            endPoint: CGPoint(x: size.width * 0.5, y: size.height)
        ))

        drawMountains(in: &context, size: size, roadRect: roadRect)

        let sideRects = [
            CGRect(x: 0, y: 0, width: roadRect.minX, height: size.height),
            CGRect(x: roadRect.maxX, y: 0, width: size.width - roadRect.maxX, height: size.height)
        ]

        for sideIndex in 0..<sideRects.count {
            let rect = sideRects[sideIndex]
            var marker = 0
            var y = -size.height * sceneryOffset
            while y < size.height + 90 {
                let centerX = rect.midX + CGFloat((marker % 3) - 1) * rect.width * 0.18
                let center = CGPoint(x: centerX, y: y + CGFloat((marker % 4) * 14))
                drawSceneryObject(in: &context, center: center, index: marker + sideIndex * 3)
                y += 82
                marker += 1
            }
        }
    }

    private func drawMountains(in context: inout GraphicsContext, size: CGSize, roadRect: CGRect) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height * 0.26))
        path.addLine(to: CGPoint(x: size.width * 0.18, y: size.height * 0.12))
        path.addLine(to: CGPoint(x: roadRect.minX, y: size.height * 0.25))
        path.addLine(to: CGPoint(x: roadRect.minX, y: size.height * 0.38))
        path.addLine(to: CGPoint(x: 0, y: size.height * 0.38))
        path.closeSubpath()
        context.fill(path, with: .color(Color.white.opacity(0.20)))

        var rightPath = Path()
        rightPath.move(to: CGPoint(x: roadRect.maxX, y: size.height * 0.28))
        rightPath.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.13))
        rightPath.addLine(to: CGPoint(x: size.width, y: size.height * 0.25))
        rightPath.addLine(to: CGPoint(x: size.width, y: size.height * 0.40))
        rightPath.addLine(to: CGPoint(x: roadRect.maxX, y: size.height * 0.40))
        rightPath.closeSubpath()
        context.fill(rightPath, with: .color(Color.white.opacity(0.18)))
    }

    private func drawSceneryObject(in context: inout GraphicsContext, center: CGPoint, index: Int) {
        switch sceneryTheme {
        case .meadow:
            if index.isMultiple(of: 2) {
                drawTree(in: &context, center: center)
            } else {
                drawFlower(in: &context, center: center)
            }
        case .lake:
            if index.isMultiple(of: 3) {
                drawSailboat(in: &context, center: center)
            } else {
                drawReed(in: &context, center: center)
            }
        case .hills:
            if index.isMultiple(of: 2) {
                drawPine(in: &context, center: center)
            } else {
                drawFlower(in: &context, center: center)
            }
        }
    }

    private func drawTree(in context: inout GraphicsContext, center: CGPoint) {
        context.fill(Path(CGRect(x: center.x - 4, y: center.y + 8, width: 8, height: 18)), with: .color(Color(red: 0.45, green: 0.26, blue: 0.12)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 18, y: center.y - 18, width: 36, height: 36)), with: .color(Color(red: 0.12, green: 0.46, blue: 0.20)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 26, width: 28, height: 28)), with: .color(Color(red: 0.18, green: 0.58, blue: 0.25)))
    }

    private func drawPine(in context: inout GraphicsContext, center: CGPoint) {
        context.fill(Path(CGRect(x: center.x - 3, y: center.y + 10, width: 6, height: 18)), with: .color(Color(red: 0.38, green: 0.22, blue: 0.10)))
        for level in 0..<3 {
            let width = CGFloat(32 - level * 7)
            let y = center.y - CGFloat(level * 12)
            var tree = Path()
            tree.move(to: CGPoint(x: center.x, y: y - 24))
            tree.addLine(to: CGPoint(x: center.x - width / 2, y: y + 10))
            tree.addLine(to: CGPoint(x: center.x + width / 2, y: y + 10))
            tree.closeSubpath()
            context.fill(tree, with: .color(Color(red: 0.08, green: 0.36, blue: 0.22)))
        }
    }

    private func drawFlower(in context: inout GraphicsContext, center: CGPoint) {
        context.stroke(Path { path in
            path.move(to: CGPoint(x: center.x, y: center.y + 12))
            path.addLine(to: CGPoint(x: center.x, y: center.y + 28))
        }, with: .color(.green.opacity(0.8)), lineWidth: 2)
        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3) {
            let petal = CGPoint(x: center.x + cos(angle) * 7, y: center.y + sin(angle) * 7)
            context.fill(Path(ellipseIn: CGRect(x: petal.x - 5, y: petal.y - 5, width: 10, height: 10)), with: .color(.pink))
        }
        context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(.yellow))
    }

    private func drawSailboat(in context: inout GraphicsContext, center: CGPoint) {
        var hull = Path()
        hull.move(to: CGPoint(x: center.x - 18, y: center.y + 12))
        hull.addLine(to: CGPoint(x: center.x + 18, y: center.y + 12))
        hull.addLine(to: CGPoint(x: center.x + 8, y: center.y + 22))
        hull.addLine(to: CGPoint(x: center.x - 12, y: center.y + 22))
        hull.closeSubpath()
        context.fill(hull, with: .color(.white.opacity(0.85)))

        var sail = Path()
        sail.move(to: CGPoint(x: center.x, y: center.y - 20))
        sail.addLine(to: CGPoint(x: center.x, y: center.y + 10))
        sail.addLine(to: CGPoint(x: center.x + 16, y: center.y + 6))
        sail.closeSubpath()
        context.fill(sail, with: .color(.orange.opacity(0.85)))
    }

    private func drawReed(in context: inout GraphicsContext, center: CGPoint) {
        for index in 0..<3 {
            let x = center.x + CGFloat(index - 1) * 7
            var reed = Path()
            reed.move(to: CGPoint(x: x, y: center.y + 24))
            reed.addLine(to: CGPoint(x: x + CGFloat(index - 1) * 4, y: center.y - 8))
            context.stroke(reed, with: .color(Color(red: 0.24, green: 0.48, blue: 0.22)), lineWidth: 2)
            context.fill(Path(ellipseIn: CGRect(x: x - 3, y: center.y - 13, width: 6, height: 14)), with: .color(Color(red: 0.56, green: 0.34, blue: 0.14)))
        }
    }

    private func drawRoad(in context: inout GraphicsContext, size: CGSize, roadRect: CGRect) {
        context.fill(Path(roadRect), with: .linearGradient(
            Gradient(colors: [Color(red: 0.18, green: 0.20, blue: 0.23), Color(red: 0.08, green: 0.09, blue: 0.11)]),
            startPoint: CGPoint(x: roadRect.midX, y: 0),
            endPoint: CGPoint(x: roadRect.midX, y: size.height)
        ))

        let laneWidth = roadRect.width / 3
        for index in 1...2 {
            let x = roadRect.minX + laneWidth * CGFloat(index)
            var y: CGFloat = 18 + (sceneryOffset * 44)
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: min(y + 24, size.height)))
                context.stroke(path, with: .color(.white.opacity(0.36)), lineWidth: 3)
                y += 44
            }
        }

        context.fill(Path(CGRect(x: roadRect.minX - 4, y: 0, width: 6, height: size.height)), with: .color(.orange))
        context.fill(Path(CGRect(x: roadRect.maxX - 2, y: 0, width: 6, height: size.height)), with: .color(.orange))
    }

    private func drawItems(in context: inout GraphicsContext, size: CGSize, roadRect: CGRect) {
        let laneWidth = roadRect.width / 3

        for item in items {
            let center = CGPoint(x: roadRect.minX + laneWidth * (CGFloat(item.lane) + 0.5), y: size.height * item.y)
            switch item.kind {
            case .cone:
                var cone = Path()
                cone.move(to: CGPoint(x: center.x, y: center.y - 21))
                cone.addLine(to: CGPoint(x: center.x - 18, y: center.y + 18))
                cone.addLine(to: CGPoint(x: center.x + 18, y: center.y + 18))
                cone.closeSubpath()
                context.fill(cone, with: .color(.orange))
                context.stroke(cone, with: .color(.white.opacity(0.55)), lineWidth: 2)
            case .star:
                context.fill(Path(ellipseIn: CGRect(x: center.x - 17, y: center.y - 17, width: 34, height: 34)), with: .color(.yellow))
                context.stroke(Path(ellipseIn: CGRect(x: center.x - 17, y: center.y - 17, width: 34, height: 34)), with: .color(.white.opacity(0.75)), lineWidth: 2)
            }
        }
    }

    private func drawPlayer(in context: inout GraphicsContext, size: CGSize, roadRect: CGRect) {
        let laneWidth = roadRect.width / 3
        let center = CGPoint(x: roadRect.minX + laneWidth * (CGFloat(playerLane) + 0.5), y: size.height * 0.84)
        let body = CGRect(x: center.x - 24, y: center.y - 36, width: 48, height: 72)
        let window = CGRect(x: center.x - 15, y: center.y - 23, width: 30, height: 23)

        context.fill(Path(roundedRect: body, cornerRadius: 12), with: .color(.blue))
        context.fill(Path(roundedRect: window, cornerRadius: 6), with: .color(.cyan.opacity(0.75)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 29, y: center.y - 24, width: 12, height: 18)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x + 17, y: center.y - 24, width: 12, height: 18)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 29, y: center.y + 12, width: 12, height: 18)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x + 17, y: center.y + 12, width: 12, height: 18)), with: .color(.black))
    }

    private func drawStartHint(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(x: size.width * 0.14, y: size.height * 0.42, width: size.width * 0.72, height: 72)
        context.fill(Path(roundedRect: rect, cornerRadius: 14), with: .color(.black.opacity(0.42)))
        let text = Text("触摸赛道开始")
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    private func drawGameOver(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.fill(Path(rect), with: .color(.black.opacity(0.45)))

        let text = Text("游戏结束")
            .font(.title.weight(.bold))
            .foregroundStyle(.white)
        context.draw(text, at: CGPoint(x: size.width * 0.5, y: size.height * 0.48), anchor: .center)
    }
}

private struct RacingStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "-" : value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        RacingGameView()
    }
}
