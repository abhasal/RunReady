import SwiftUI
import SwiftData
import MapKit

struct ActiveRunView: View {
    @Environment(AppState.self) private var appState
    @Environment(UserPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActiveRunViewModel()
    @State private var showFinishConfirm = false
    @State private var showSavedBanner = false
    @State private var isMusicExpanded = false

    var body: some View {
        ZStack {
            // Dark full-screen background for active run
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Map (top 45%)
                liveMap
                    .frame(maxHeight: .infinity)

                // Stats panel
                statsPanel
                    .background(Color(uiColor: .systemBackground))
            }

            // Finish confirmation alert is handled via .alert modifier

            // Saved banner
            if showSavedBanner {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Run saved!")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showSavedBanner)
            }
        }
        .alert("Finish Run?", isPresented: $showFinishConfirm) {
            Button("Save & Finish", role: .none) { finishAndSave() }
            Button("Keep Running", role: .cancel) {}
            Button("Discard", role: .destructive) { dismiss() }
        } message: {
            Text("Your run will be saved to your history.")
        }
        .statusBar(hidden: true)
        .onDisappear {
            if viewModel.state == .running || viewModel.state == .paused {
                viewModel.reset()
            }
        }
    }

    // MARK: - Map

    private var liveMap: some View {
        ZStack(alignment: .topTrailing) {
            if viewModel.routePoints.isEmpty {
                mapPlaceholder
            } else {
                RouteMapView(routePoints: viewModel.routePoints)
            }

            // Close button
            Button {
                if viewModel.state == .idle { dismiss() }
                else { showFinishConfirm = true }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .shadow(radius: 3)
            }
            .padding(20)
        }
    }

    private var mapPlaceholder: some View {
        ZStack {
            Color(uiColor: .systemGray6)
            VStack(spacing: 8) {
                Image(systemName: "location.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Waiting for GPS…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(spacing: 20) {
            // Primary metrics
            HStack(spacing: 0) {
                metricColumn(
                    value: UnitConversionService.formattedDistanceCompact(viewModel.distanceMeters, unit: prefs.unitSystem),
                    label: "Distance"
                )
                Divider().frame(height: 50)
                metricColumn(
                    value: UnitConversionService.formattedDuration(viewModel.elapsedSeconds),
                    label: "Time"
                )
                Divider().frame(height: 50)
                metricColumn(
                    value: viewModel.currentPaceSecondsPerMeter > 0
                        ? UnitConversionService.formattedPace(
                            secondsPerMeter: viewModel.currentPaceSecondsPerMeter,
                            unit: prefs.unitSystem)
                        : "--:--",
                    label: "Pace"
                )
            }
            .padding(.top, 20)

            // Location denied warning
            if viewModel.locationAuthDenied {
                Label("Location access denied. Open Settings to enable GPS tracking.", systemImage: "location.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal)
            }

            // Controls
            controlButtons

            // Music mini-player
            miniMusicPlayer

            Spacer(minLength: 16)
        }
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var controlButtons: some View {
        HStack(spacing: 24) {
            switch viewModel.state {
            case .idle:
                startButton
            case .running:
                pauseButton
                endButton
            case .paused:
                resumeButton
                endButton
            case .finished:
                EmptyView()
            }
        }
    }

    private var startButton: some View {
        Button {
            viewModel.startRun()
        } label: {
            Image(systemName: "play.fill")
                .font(.largeTitle)
                .frame(width: 70, height: 70)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
    }

    private var pauseButton: some View {
        Button {
            viewModel.pauseRun()
        } label: {
            Image(systemName: "pause.fill")
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
    }

    private var resumeButton: some View {
        Button {
            viewModel.resumeRun()
        } label: {
            Image(systemName: "play.fill")
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
    }

    private var endButton: some View {
        Button {
            showFinishConfirm = true
        } label: {
            Image(systemName: "stop.fill")
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Color.red)
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
    }

    // MARK: - Mini music player

    private var miniMusicPlayer: some View {
        let audio = appState.audioPlayer
        return HStack(spacing: 12) {
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(audio.currentTrack?.title ?? "No track")
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(audio.currentTrack?.artist ?? "Tap to play music")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            // Controls
            Button {
                audio.previous()
            } label: {
                Image(systemName: "backward.fill").font(.subheadline)
            }
            Button {
                if audio.currentTrack == nil {
                    audio.play(track: Playlist.builtIn.tracks[0])
                } else {
                    audio.togglePlayPause()
                }
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline)
            }
            Button {
                audio.next()
            } label: {
                Image(systemName: "forward.fill").font(.subheadline)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func finishAndSave() {
        guard let run = viewModel.finishRun() else {
            dismiss()
            return
        }
        do {
            let store = RunStore(modelContext: modelContext)
            try store.save(run)
            withAnimation { showSavedBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        } catch {
            print("[ActiveRunView] Save error: \(error)")
            dismiss()
        }
    }
}

#Preview {
    ActiveRunView()
        .environment(AppState())
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
