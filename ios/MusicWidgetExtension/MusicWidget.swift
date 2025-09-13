import WidgetKit
import SwiftUI
import Intents

// Define actions for the widget buttons
enum MusicWidgetAction: String {
    case playPause
    case previous
    case next
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), songTitle: "Loading Song...", artistName: "Loading Artist...", albumArt: UIImage(named: "default_album_art"), isPlaying: false)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Example data for snapshot
        let entry = SimpleEntry(date: Date(), configuration: configuration, songTitle: "Song Title", artistName: "Artist Name", albumArt: UIImage(named: "default_album_art"), isPlaying: true)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline entry for the current time and a refresh after 15 minutes.
        let currentDate = Date()
        // In a real app, you would fetch current song data here
        let entry = SimpleEntry(date: currentDate, configuration: configuration, songTitle: "Song Title", artistName: "Artist Name", albumArt: UIImage(named: "default_album_art"), isPlaying: true)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let songTitle: String
    let artistName: String
    let albumArt: UIImage?
    let isPlaying: Bool
}

struct MusicWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.65, blue: 0.15), Color(red: 0.98, green: 0.55, blue: 0.0)]), startPoint: .leading, endPoint: .trailing)
                .cornerRadius(16)
                .shadow(radius: 5)

            HStack {
                if let albumArt = entry.albumArt {
                    Image(uiImage: albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading) {
                    Text(entry.songTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(entry.artistName)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.leading, 8)

                Spacer()

                HStack(spacing: 16) {
                    Button(intent: PlaybackIntent(action: MusicWidgetAction.previous.rawValue)) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(red: 0.98, green: 0.55, blue: 0.0).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle()) // To remove default button styling

                    Button(intent: PlaybackIntent(action: MusicWidgetAction.playPause.rawValue)) {
                        Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color(red: 0.98, green: 0.43, blue: 0.0))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(intent: PlaybackIntent(action: MusicWidgetAction.next.rawValue)) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(red: 0.98, green: 0.55, blue: 0.0).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

@main
struct MusicWidget: Widget {
    let kind: String = "MusicWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: PlaybackIntent.self, provider: Provider()) { entry in
            MusicWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("JTunes Music Player")
        .description("Displays the current playing song and controls.")
        .supportedFamilies([.systemMedium])
    }
}

struct MusicWidget_Previews: PreviewProvider {
    static var previews: some View {
        MusicWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), songTitle: "Song Title", artistName: "Artist Name", albumArt: UIImage(named: "default_album_art"), isPlaying: true))
            .previewContext(WidgetConfigurationContext(family: .systemMedium))
    }
}
