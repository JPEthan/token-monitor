import SwiftUI

struct MonitorView: View {
    @ObservedObject var model: MonitorViewModel
    let onShowDesktopWidget: () -> Void
    @State private var showingSettings = false
    @State private var acknowledgedAdminKeyRisk = false

    private var panelHeight: CGFloat {
        showingSettings || !model.hasSavedAPIKey ? 690 : 520
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    quotaCard
                    breakdown
                    status
                    actionBar

                    if showingSettings || !model.hasSavedAPIKey {
                        settings
                    }

                    disclosure
                    legalNotice
                }
                .padding(16)
            }
        }
        .frame(width: 390, height: panelHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .background {
            MenuBarWindowSizer(contentSize: NSSize(width: 390, height: panelHeight))
                .frame(width: 0, height: 0)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green.gradient)
                    .frame(width: 32, height: 32)
                Image(systemName: "number")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(model.text(.appTitle))
                    .font(.headline)
                Text(model.text(.monthlyUsage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingSettings.toggle()
            } label: {
                Image(systemName: showingSettings ? "xmark" : "gearshape")
            }
            .buttonStyle(.plain)
            .help(model.text(showingSettings ? .closeSettings : .settings))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var quotaCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.text(.remainingToken))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(TokenFormat.full(model.remainingTokens))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if model.overLimitTokens > 0 {
                        Text("\(model.text(.overLimit)) \(TokenFormat.full(model.overLimitTokens))")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.16), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: model.usageFraction)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text(model.usageFraction.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                .frame(width: 64, height: 64)
            }

            ProgressView(value: model.usageFraction)
                .tint(progressColor)

            HStack {
                Text("\(model.text(.used)) \(TokenFormat.full(model.usedTokens))")
                Spacer()
                Text("\(model.text(.quota)) \(TokenFormat.full(model.monthlyTokenLimit))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.12))
        }
    }

    private var breakdown: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metric(model.text(.input), model.snapshot.inputTokens, icon: "arrow.down.left", color: .blue)
            metric(model.text(.output), model.snapshot.outputTokens, icon: "arrow.up.right", color: .purple)
            metric(model.text(.cachedInput), model.snapshot.cachedInputTokens, icon: "bolt", color: .orange)
            metric(model.text(.requests), model.snapshot.requests, icon: "paperplane", color: .green)
        }
    }

    private func metric(_ title: String, _ value: Int64, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(TokenFormat.full(value))
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }

    private var status: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: model.statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(model.statusIsError ? .red : .green)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.statusMessage)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = model.lastUpdated {
                    Text("\(model.text(.updated))\(model.language == .english ? ": " : "：")\(date.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var actionBar: some View {
        HStack {
            Button {
                model.playDuckSound()
                onShowDesktopWidget()
                Task {
                    await model.refresh(revealWidget: true)
                }
            } label: {
                Label(
                    model.isRefreshing ? model.text(.syncing) : model.text(.refreshAndShow),
                    systemImage: "arrow.clockwise"
                )
            }
            .help(model.text(.refreshHelp))

            Button(model.text(.officialUsage)) {
                model.openUsageDashboard()
            }

            Spacer()

            Button(model.text(.quit)) {
                model.quit()
            }
        }
        .controlSize(.small)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(model.text(.settings), systemImage: "gearshape")
                .font(.subheadline.bold())

            HStack {
                Text(model.text(.language))
                Spacer()
                Picker(model.text(.language), selection: $model.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Toggle(model.text(.duckSound), isOn: $model.soundEffectsEnabled)
                        .toggleStyle(.switch)
                    Spacer()
                    Button(model.text(.previewSound)) {
                        model.playDuckSound(force: true)
                    }
                    .controlSize(.small)
                }
                Text(model.text(.duckSoundHelp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("OpenAI Admin API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    SecureField(model.hasSavedAPIKey ? model.text(.apiKeyStoredPlaceholder) : "sk-admin-…", text: $model.apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                    Button(model.hasSavedAPIKey ? model.text(.replace) : model.text(.save)) {
                        Task {
                            await model.saveAPIKey()
                            acknowledgedAdminKeyRisk = false
                        }
                    }
                    .disabled(
                        model.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || !acknowledgedAdminKeyRisk
                    )
                }
                Text(model.text(.keychainNotice))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Toggle(
                    model.text(.acknowledgeAdminKeyRisk),
                    isOn: $acknowledgedAdminKeyRisk
                )
                .toggleStyle(.checkbox)
                .font(.caption2)
            }

            HStack {
                Text(model.text(.monthlyQuota))
                Spacer()
                TextField(
                    model.text(.monthlyQuota),
                    value: $model.monthlyTokenLimit,
                    format: .number.grouping(.never)
                )
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 150)
            }

            HStack {
                Text(model.text(.automaticSync))
                Spacer()
                Picker(model.text(.automaticSync), selection: $model.refreshCadence) {
                    ForEach(RefreshCadence.allCases) { cadence in
                        Text(cadence.label(language: model.language)).tag(cadence)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            if model.hasSavedAPIKey {
                Button(model.text(.removeKey), role: .destructive) {
                    model.removeAPIKey()
                }
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private var disclosure: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(model.text(.calculation))
                .font(.caption.bold())
            Text(model.text(.calculationDetails))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var legalNotice: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(model.text(.legalTitle), systemImage: "exclamationmark.shield")
                .font(.caption.bold())
            Text(model.text(.legalSummary))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button(model.text(.openDisclaimer)) {
                    model.openBundledLegalDocument(named: "DISCLAIMER")
                }
                Button(model.text(.openPrivacy)) {
                    model.openBundledLegalDocument(named: "PRIVACY")
                }
            }
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.22))
        }
    }

    private var progressColor: Color {
        if model.usageFraction >= 0.95 { return .red }
        if model.usageFraction >= 0.75 { return .orange }
        return .green
    }
}
