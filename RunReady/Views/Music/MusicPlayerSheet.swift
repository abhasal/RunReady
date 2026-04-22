import SwiftUI

struct MusicPlayerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var audio: AudioPlaybackManager { appState.audioPlayer }
    private var tracks: [AudioTrack] { Playlist.builtIn.tracks }

    var body: some View {
        NavigationStack {
            ZStack {
                RunReadyGradient()

                VStack(spacing: 28) {
                    // Album art placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [.orange.opacity(0.6), .red.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 220, height: 220)
                        Image(systemName: "music.note")
                            .font(.system(size: 70))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .shadow(radius: 20)
                    .padding(.top, 20)

                    // Track info
                    VStack(spacing: 6) {
                        Text(audio.currentTrack?.title ?? "Not Playing")
                            .font(.title2.bold())
                            .lineLimit(1)
                        Text(audio.currentTrack?.artist ?? "Choose a track below")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Progress bar
                    VStack(spacing: 4) {
                        ProgressView(
                            value: audio.currentTrack.map { track in
                                track.duration > 0 ? audio.currentTime / track.duration : 0
                            } ?? 0
                        )
                        .tint(.orange)
                        HStack {
                            Text(UnitConversionService.formattedDuration(audio.currentTime))
                                .font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text(UnitConversionService.formattedDuration(audio.currentTrack?.duration ?? 0))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 30)

                    // Controls
                    HStack(spacing: 40) {
                        Button { audio.previous() } label: {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                        }
                        Button {
                            if audio.currentTrack == nil {
                                audio.play(track: tracks[0])
                            } else {
                                audio.togglePlayPause()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 65, height: 65)
                                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                        Button { audio.next() } label: {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                        }
                    }
                    .foregroundStyle(.primary)

                    // Volume
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill").foregroundStyle(.secondary).font(.caption)
                        Slider(value: Binding(
                            get: { Double(audio.volume) },
                            set: { audio.setVolume(Float($0)) }
                        ))
                        .tint(.orange)
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary).font(.caption)
                    }
                    .padding(.horizontal, 30)

                    // Track list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Tracks")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        ForEach(tracks) { track in
                            Button {
                                audio.play(track: track)
                            } label: {
                                HStack {
                                    Image(systemName: audio.currentTrack?.id == track.id && audio.isPlaying
                                          ? "speaker.wave.2.fill" : "music.note")
                                        .foregroundStyle(audio.currentTrack?.id == track.id ? .orange : .secondary)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(audio.currentTrack?.id == track.id ? .orange : .primary)
                                        Text(track.artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(UnitConversionService.formattedDurationCompact(track.duration))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(
                                    audio.currentTrack?.id == track.id
                                        ? Color.orange.opacity(0.08)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 52)
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    Spacer(minLength: 16)
                }
            }
            .navigationTitle("Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    MusicPlayerSheet()
        .environment(AppState())
}
