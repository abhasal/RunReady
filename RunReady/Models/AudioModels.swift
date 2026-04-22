import Foundation

struct AudioTrack: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    /// Filename in the app bundle, e.g. "run_track_01.mp3"
    let filename: String
    let duration: TimeInterval

    static func == (lhs: AudioTrack, rhs: AudioTrack) -> Bool { lhs.id == rhs.id }
}

struct Playlist: Identifiable {
    let id: UUID
    let name: String
    var tracks: [AudioTrack]
}

// MARK: - Bundled sample tracks (replace with real audio files in Xcode)
// TODO: Add .mp3 or .m4a files to the Xcode project Resources group with these exact filenames.
extension Playlist {
    static let builtIn = Playlist(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
        name: "Running Playlist",
        tracks: [
            AudioTrack(
                id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
                title: "Pace Setter",
                artist: "RunReady Beats",
                filename: "pace_setter.mp3",
                duration: 210
            ),
            AudioTrack(
                id: UUID(uuidString: "11111111-0000-0000-0000-000000000002")!,
                title: "Steady Stride",
                artist: "RunReady Beats",
                filename: "steady_stride.mp3",
                duration: 195
            ),
            AudioTrack(
                id: UUID(uuidString: "11111111-0000-0000-0000-000000000003")!,
                title: "Final Push",
                artist: "RunReady Beats",
                filename: "final_push.mp3",
                duration: 180
            )
        ]
    )
}
