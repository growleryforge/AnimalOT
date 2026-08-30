import SwiftUI
import SwiftData

// MARK: - The play surface (where he becomes the animal AND has something to do)
//
// Two loops share this surface:
//  • LADDER (donkey, pig): mouth-open does the mischief and charges a meter; the
//    world escalates until a big BLOWOUT payoff, then resets and invites another.
//  • SNEAK (raccoon): he creeps up on a treasure by holding STILL, then POUNCES
//    (mouth-open lunge) to snatch it — real movement grading and timing.
//
// Both obey the same rules: no score, no fail, escalating glee, bailing is data.

struct AnimalGameView: View {
    let game: Game

    @Environment(\.modelContext) private var context
    @Environment(Provisioning.self) private var provisioning
    @Environment(\.dismiss) private var dismiss

    @State private var sound = SoundEngine()
    @State private var controller: KidSessionController?
    @State private var config: AnimalMaskConfig = .config(for: .donkey)
    @State private var kind: AnimalKind = .donkey
    @State private var theme = MischiefTheme.theme(for: .donkey)

    @State private var meter = MischiefMeter()   // ladder (donkey / pig)
    @State private var sneak = SneakMeter()       // sneak (raccoon)

    @State private var gleeBursts: [GleeBurst] = []
    @State private var blowoutBurst: [GleeBurst] = []
    @State private var trackingHeld = true
    @State private var shake = CGSize.zero
    @State private var showCoach = true

    private var isSneak: Bool { kind == .raccoon }

    /// Big, simple "what to do" shown at the start of every game.
    private var coachText: String {
        switch kind {
        case .lion:    return "Open your mouth\nto ROAR! 🦁"
        case .donkey:  return "Throw your head BACK\nto KICK! 🫏"
        case .pig:     return "Open your mouth\nto get MESSY! 🐷"
        case .raccoon: return "Hold STILL to sneak up…\nthen open WIDE to POUNCE! 🍪"
        }
    }

    /// Short reminder kept on screen above the meter for the ladder animals.
    private var meterHint: String {
        switch kind {
        case .lion:   return "Open wide to fill it up! 🦁"
        case .donkey: return "Tip your head back to fill it up! 🫏"
        case .pig:    return "Open wide to fill it up! 🐷"
        case .raccoon: return ""
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            FaceMaskView(
                config: config,
                onMouthFire: handleMouthFire,
                onTrackingChange: { trackingHeld = $0 },
                onMotion: { if isSneak { sneak.registerMotion($0) } },
                onHeadThrust: { handleLadderFire($0) }   // donkey buck
            )
            .ignoresSafeArea()

            // Build-up puffs (both modes).
            ForEach(gleeBursts) { burst in
                Text(burst.symbol)
                    .font(.system(size: 50 + burst.escalation * 90))
                    .position(burst.position)
                    .transition(.scale.combined(with: .opacity))
            }

            if isSneak {
                sneakContent
            } else {
                ladderContent
            }

            VStack {
                topBar
                if isSneak { stashTray.padding(.top, 4) }
                Spacer()
                if !trackingHeld {
                    Text("hold still, little \(game.animalTheme)…")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .transition(.opacity)
                }
                Spacer()
                if isSneak { sneakBar } else { chargeMeter }
            }
            .padding()

            // Clear, simple coaching at the start — what to do, in a few words.
            if showCoach {
                coachBubble
            }
        }
        .offset(shake)
        .statusBarHidden()
        .onAppear(perform: begin)
        .onChange(of: meter.blowoutTick) { _, _ in eruptVisuals() }
        .onChange(of: sneak.catchTick) { _, _ in spawnCrumbs() }
        .onChange(of: sneak.feastTick) { _, _ in eruptFeast() }
        .onDisappear {
            meter.stop()
            controller?.end()
        }
    }

    // MARK: Shared chrome

    private var topBar: some View {
        HStack {
            Button {
                controller?.end()
                dismiss()
            } label: {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(12)
                    .background(.black.opacity(0.3), in: Circle())
            }
            Button(action: replayCoach) {
                Image(systemName: "questionmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(12)
                    .background(.black.opacity(0.3), in: Circle())
            }
            Spacer()
            let tally = isSneak ? sneak.caught : meter.blowoutCount
            if tally > 0 {
                Text("\(theme.payoffEmoji) ✕ \(tally)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(theme.barColor.opacity(0.5), in: Capsule())
            }
        }
    }

    // MARK: Ladder mode (donkey / pig)

    private var ladderContent: some View {
        ZStack {
            // "Powering up" glow that intensifies with the meter.
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(theme.barColor.opacity(0.15 + meter.charge * 0.7),
                              lineWidth: 6 + meter.charge * 36)
                .blur(radius: 8)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeOut(duration: 0.2), value: meter.charge)

            if meter.isBlowingOut { payoffOverlay }
        }
    }

    private var coachBubble: some View {
        Text(coachText)
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 32).padding(.vertical, 26)
            .background(theme.barColor.opacity(0.85), in: RoundedRectangle(cornerRadius: 32))
            .overlay(RoundedRectangle(cornerRadius: 32).strokeBorder(.white.opacity(0.7), lineWidth: 3))
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            .padding(40)
            .transition(.scale.combined(with: .opacity))
    }

    private var chargeMeter: some View {
        VStack(spacing: 6) {
            if !meterHint.isEmpty {
                Text(meterHint)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 3)
            }
            Text(meter.tier >= 3 ? "LET IT RIP!" : theme.powerLabel)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white).shadow(radius: 3)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.35))
                    Capsule()
                        .fill(theme.barColor)
                        .frame(width: max(18, geo.size.width * meter.charge))
                        .overlay(alignment: .trailing) {
                            Text(theme.buildEmojis.first ?? "💨")
                                .font(.system(size: 26))
                                .scaleEffect(meter.tier >= 3 ? 1.3 : 1.0)
                                .offset(x: 8)
                        }
                        .animation(.easeOut(duration: 0.2), value: meter.charge)
                }
            }
            .frame(height: 26)
        }
        .padding(.horizontal, 8)
    }

    // MARK: Sneak mode (raccoon)

    /// The stash tray — the GOAL, always visible. Fill 3 cookies → FULL BELLY.
    private var stashTray: some View {
        HStack(spacing: 10) {
            ForEach(0..<sneak.stashGoal, id: \.self) { i in
                if i < sneak.stash {
                    CookieView().frame(width: 36, height: 36)
                        .transition(.scale)
                } else {
                    Circle()
                        .strokeBorder(.white.opacity(0.6),
                                      style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        .frame(width: 36, height: 36)
                }
            }
            Text("Catch 3 for a FULL BELLY!")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white).shadow(radius: 2)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(.black.opacity(0.32), in: Capsule())
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: sneak.stash)
    }

    private var sneakContent: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let topY = geo.size.height * 0.22
            let grabY = geo.size.height * 0.48
            let y = topY + (grabY - topY) * sneak.charge
            let size = 80 + 150 * sneak.charge

            ZStack {
                // The active cookie creeps closer and bigger as he holds still,
                // and GLOWS when it's ready to grab.
                CookieView(glow: sneak.isReady && sneak.phase == .sneaking)
                    .frame(width: size, height: size)
                    .scaleEffect(sneak.phase == .caught ? 1.4 : 1.0)
                    .opacity(sneak.phase == .skittered ? 0 : 1)
                    .rotationEffect(.degrees(sneak.phase == .skittered ? 55 : 0))
                    .position(x: w / 2 + (sneak.phase == .skittered ? 220 : 0),
                              y: sneak.phase == .caught ? geo.size.height * 0.5 : y)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: sneak.phase)
                    .animation(.easeOut(duration: 0.12), value: sneak.charge)

                // One big, clear cue.
                VStack {
                    Spacer()
                    cueLabel(sneakCue.text, sneakCue.color)
                    Spacer().frame(height: geo.size.height * 0.18)
                }
                .frame(maxWidth: .infinity)

                // Catch crumbs / feast confetti.
                ForEach(blowoutBurst) { burst in
                    Text(burst.symbol)
                        .font(.system(size: 60 + burst.escalation * 70))
                        .position(burst.position)
                }

                if sneak.justFeasted {
                    ZStack {
                        Color.pink.opacity(0.30).ignoresSafeArea()
                        VStack(spacing: 12) {
                            Text("🦝").font(.system(size: 150))
                            Text("FULL BELLY!")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundStyle(.white).shadow(radius: 8)
                            Text("Belly #\(sneak.feasts + 1) 🎉")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.95))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var sneakCue: (text: String, color: Color) {
        switch sneak.phase {
        case .caught:
            return sneak.justFeasted ? ("FULL BELLY! 🎉", .green) : ("YUM! 🍪", .green)
        case .skittered:
            return ("so close… sneak again 🤫", .purple)
        case .sneaking:
            if sneak.isReady { return ("POUNCE now! open wide 😼", .pink) }
            if sneak.charge > 0.05 && sneak.isStill { return ("creeping closer… 🐾", .purple) }
            if sneak.charge > 0.05 { return ("freeeeze! 🤫", .indigo) }
            return ("hold still to sneak up 🤫", .purple)
        }
    }

    private func cueLabel(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 22).padding(.vertical, 12)
            .background(color.opacity(0.7), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 2))
            .shadow(radius: 5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: text)
    }

    private var sneakBar: some View {
        VStack(spacing: 6) {
            Text(sneak.isReady ? "POUNCE! 😼" : "SNEAK POWER — hold still")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white).shadow(radius: 3)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.35))
                    Capsule()
                        .fill(sneak.isReady ? Color.pink : Color.purple)
                        .frame(width: max(18, geo.size.width * sneak.charge))
                        .overlay(alignment: .trailing) {
                            Text(sneak.isReady ? "😼" : "🦝")
                                .font(.system(size: 26)).offset(x: 8)
                        }
                        .animation(.easeOut(duration: 0.12), value: sneak.charge)
                }
            }
            .frame(height: 26)
        }
        .padding(.horizontal, 8)
    }

    // MARK: Payoff (ladder blowout)

    private var payoffOverlay: some View {
        ZStack {
            theme.barColor.opacity(0.25).ignoresSafeArea()
            ForEach(blowoutBurst) { burst in
                Text(burst.symbol)
                    .font(.system(size: 70 + burst.escalation * 80))
                    .position(burst.position)
            }
            VStack(spacing: 12) {
                Text(theme.payoffEmoji).font(.system(size: 150))
                Text(theme.payoffText)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white).shadow(radius: 6)
                    .multilineTextAlignment(.center)
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: Wiring

    private func begin() {
        kind = AnimalKind.forGame(game)
        config = .config(for: kind)
        theme = .theme(for: kind)
        sound.preload(config.soundNames)
        if isSneak { sneak.start() } else { meter.start() }
        let c = KidSessionController(context: context, deviceId: provisioning.deviceId)
        c.begin(game: game)
        controller = c

        // Show the coach for a few seconds, then fade it so it doesn't block play.
        showCoach = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeInOut(duration: 0.5)) { showCoach = false }
        }
    }

    /// Bring the coach back when he taps the hint area (gentle re-explain).
    private func replayCoach() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showCoach = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeInOut(duration: 0.5)) { showCoach = false }
        }
    }

    private func handleMouthFire(_ rawEscalation: Double) {
        if isSneak {
            handlePounce()
        } else {
            handleLadderFire(rawEscalation)
        }
    }

    private func handlePounce() {
        let caught = sneak.pounce()
        sound.fire(caught ? "pounce" : "chitter", escalation: caught ? 1.0 : 0.35)
        controller?.logFire(escalation: sneak.charge)
        if caught { controller?.log(.complete, value: "caught") }
    }

    private func handleLadderFire(_ rawEscalation: Double) {
        let charge = meter.registerFire()
        let escalation = max(rawEscalation, charge)

        let name = config.soundNames.randomElement() ?? "fart"
        sound.fire(name, escalation: escalation)
        controller?.logFire(escalation: escalation)
        spawnGlee(escalation: escalation)

        if meter.tier >= 2 {
            let amp: CGFloat = meter.tier >= 3 ? 16 : 8
            withAnimation(.easeInOut(duration: 0.06)) {
                shake = CGSize(width: .random(in: -amp...amp), height: .random(in: -amp...amp))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { shake = .zero }
            }
        }
    }

    private func spawnGlee(escalation: Double) {
        let burst = GleeBurst(
            symbol: theme.buildEmojis.randomElement() ?? "💨",
            escalation: escalation,
            position: CGPoint(x: CGFloat.random(in: 70...330),
                              y: CGFloat.random(in: 180...560))
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { gleeBursts.append(burst) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut) { gleeBursts.removeAll { $0.id == burst.id } }
        }
    }

    private func eruptVisuals() {
        let bursts = (0..<14).map { _ in
            GleeBurst(
                symbol: theme.burstEmojis.randomElement() ?? "💥",
                escalation: Double.random(in: 0.3...1.0),
                position: CGPoint(x: .random(in: 40...360), y: .random(in: 120...700))
            )
        }
        blowoutBurst = bursts
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { blowoutBurst = [] }
    }

    /// Little crumb pop + chomp on each cookie catch.
    private func spawnCrumbs() {
        sound.fire("pounce", escalation: 0.5)
        let syms = ["🍪", "✨", "😋", "🤤", "💛"]
        blowoutBurst = (0..<10).map { _ in
            GleeBurst(symbol: syms.randomElement() ?? "🍪",
                      escalation: Double.random(in: 0.2...0.7),
                      position: CGPoint(x: .random(in: 90...300), y: .random(in: 260...560)))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { blowoutBurst = [] }
    }

    /// BIG celebration when the belly fills — lots of confetti, sound, held longer.
    private func eruptFeast() {
        sound.fire("pounce", escalation: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { sound.fire("chitter", escalation: 1.0) }
        let syms = ["🦝", "🍪", "🎉", "⭐️", "✨", "💥", "😆", "🥳"]
        blowoutBurst = (0..<40).map { _ in
            GleeBurst(symbol: syms.randomElement() ?? "🎉",
                      escalation: Double.random(in: 0.4...1.0),
                      position: CGPoint(x: .random(in: 20...380), y: .random(in: 60...780)))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { blowoutBurst = [] }
    }
}

struct GleeBurst: Identifiable {
    let id = UUID()
    let symbol: String
    let escalation: Double
    let position: CGPoint
}
