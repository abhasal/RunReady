import SwiftUI

/// Persistent mini-player bar shown at the bottom of any tab when music is active.
struct MiniPlayerView: View {
    @Environment(AppState.self) private var appState
    @State private var showFullPlayer = false

    private var audio: AudioPlaybackManager { appState.audioPlayer }

    var body: some View {
        if audio.currentTrack != nil {
            HStack(spacing: 14) {
                Image(systemName: "music.note")
                    .foregroundStyle(.orange)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text(audio.currentTrack?.title ?? "")
                        .font(.caption.bold())
                        .lineLimit(1)
                    Text(audio.currentTrack?.artist ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button { audio.togglePlayPause() } label: {
                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline)
                }

                Button { audio.next() } label: {
                    Image(systemName: "forward.fill")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 12)
            .onTapGesture { showFullPlayer = true }
            .sheet(isPresented: $showFullPlayer) {
                MusicPlayerSheet()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
