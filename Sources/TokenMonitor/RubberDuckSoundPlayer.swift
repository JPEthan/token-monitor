import AVFoundation

@MainActor
final class RubberDuckSoundPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0

    init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.52
        engine.prepare()
    }

    func play() {
        let duration = 0.34
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let samples = buffer.floatChannelData?[0]
        else { return }

        buffer.frameLength = frameCount
        var phase = 0.0
        var noiseState: UInt32 = 0xD0C0_2026

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let segmentStart = time < 0.14 ? 0.0 : 0.14
            let localTime = time - segmentStart
            let segmentDuration = time < 0.14 ? 0.14 : 0.20
            let progress = min(max(localTime / segmentDuration, 0), 1)

            let startFrequency = time < 0.14 ? 1_420.0 : 1_080.0
            let endFrequency = time < 0.14 ? 760.0 : 520.0
            let wobble = 55.0 * sin(2.0 * .pi * 19.0 * time)
            let frequency = startFrequency + (endFrequency - startFrequency) * progress + wobble
            phase += 2.0 * .pi * frequency / sampleRate

            let attack = min(localTime / 0.008, 1)
            let decay = pow(max(1.0 - progress, 0), 0.72)
            let envelope = attack * decay

            noiseState = 1_664_525 &* noiseState &+ 1_013_904_223
            let noise = (Double(noiseState) / Double(UInt32.max) - 0.5) * 0.055
            let tone = sin(phase) + 0.34 * sin(phase * 2.03) + 0.15 * sin(phase * 3.97)
            samples[frame] = Float((tone * 0.46 + noise) * envelope)
        }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: [.interrupts])
            player.play()
        } catch {
            // Sound is optional; token monitoring must continue if audio output is unavailable.
        }
    }
}
