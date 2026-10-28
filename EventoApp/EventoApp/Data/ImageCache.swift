import SwiftUI
import UIKit

/// Caché en memoria y en disco de las fotos de expositores.
actor ImageCache {
    static let shared = ImageCache()
    private let memory = NSCache<NSURL, UIImage>()
    private let directory: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("speaker-photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func image(for url: URL) async -> UIImage? {
        if let img = memory.object(forKey: url as NSURL) { return img }
        let file = directory.appendingPathComponent(Self.key(url))
        if let data = try? Data(contentsOf: file), let img = UIImage(data: data) {
            memory.setObject(img, forKey: url as NSURL)
            return img
        }
        guard let result = try? await URLSession.shared.data(from: url), let img = UIImage(data: result.0) else { return nil }
        try? result.0.write(to: file, options: .atomic)
        memory.setObject(img, forKey: url as NSURL)
        return img
    }

    private static func key(_ url: URL) -> String {
        String(url.absoluteString.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" })
    }
}

struct SpeakerAvatar: View {
    let speaker: Speaker
    var size: CGFloat = 44
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle().fill(Color.accentColor.opacity(0.15))
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(speaker.initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
        .task(id: speaker.photoURL) {
            if let url = speaker.photoURL { image = await ImageCache.shared.image(for: url) }
        }
    }
}
