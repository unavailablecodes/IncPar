import SwiftUI
import UIKit

struct PetSpriteView: View {
    let sheet: PetSpriteSheet
    var scale: CGFloat = 0.56
    var animationDuration: Double = 0.22
    var blinkPause: Bool = false

    @State private var frameIndex: Int = 0
    @State private var spriteImage: UIImage?

    var body: some View {
        let frameWidth = sheet.frameSize.width * scale
        let frameHeight = sheet.frameSize.height * scale
        let currentFrame = spriteFrameImage()

        ZStack {
            if let currentFrame {
                Image(uiImage: currentFrame)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: frameWidth, height: frameHeight)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
            }
        }
        .frame(width: frameWidth, height: frameHeight)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task(id: sheet.assetName) {
            spriteImage = loadSpriteImage()
            frameIndex = 0

            while !Task.isCancelled {
                let currentFrame = sheet.idleSequence[frameIndex % max(1, sheet.idleSequence.count)]
                frameIndex = (frameIndex + 1) % max(1, sheet.idleSequence.count)

                let baseDelay = max(120, Int(animationDuration * 1000))
                let blinkDelay = blinkPause && currentFrame == 2 ? 170 : 0
                try? await Task.sleep(for: .milliseconds(baseDelay + blinkDelay))
            }
        }
        .accessibilityHidden(true)
    }

    private func spriteFrameImage() -> UIImage? {
        guard let spriteImage, let cgImage = spriteImage.cgImage else {
            return nil
        }

        let sequence = sheet.idleSequence
        guard !sequence.isEmpty else { return spriteImage }

        let currentFrame = sequence[frameIndex % sequence.count]
        let maxFrameIndex = sheet.columns * sheet.rows
        guard currentFrame >= 0, currentFrame < maxFrameIndex else {
            return spriteImage
        }

        let columns = max(1, sheet.columns)
        let rows = max(1, sheet.rows)
        let column = currentFrame % columns
        let row = currentFrame / columns

        let cellWidth = cgImage.width / columns
        let cellHeight = cgImage.height / rows
        let cropRect = CGRect(
            x: column * cellWidth,
            y: row * cellHeight,
            width: cellWidth,
            height: cellHeight
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return spriteImage
        }

        return UIImage(cgImage: cropped, scale: spriteImage.scale, orientation: spriteImage.imageOrientation)
    }

    private func loadSpriteImage() -> UIImage? {
        let bundle = Bundle.main
        let candidates = [
            bundle.url(forResource: sheet.assetName, withExtension: "png", subdirectory: "Pets"),
            bundle.url(forResource: sheet.assetName, withExtension: "png")
        ]

        for url in candidates.compactMap({ $0 }) {
            if let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }

        return nil
    }
}
