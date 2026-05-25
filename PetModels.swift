import SwiftUI

struct PetSpriteSheet: Identifiable, Hashable {
    let id: String
    let assetName: String
    let frameSize: CGSize
    let columns: Int
    let rows: Int
    let idleSequence: [Int]
}

enum AppPetLibrary {
    static let mochiPlayful = PetSpriteSheet(
        id: "mochi-playful",
        assetName: "mochi_playful",
        frameSize: CGSize(width: 192, height: 208),
        columns: 8,
        rows: 9,
        idleSequence: [
            0, 1, 3, 4, 5, 4, 3, 1,
            0, 1, 3, 4, 5, 4, 3, 1,
            0, 1, 3, 4, 5, 4, 3, 1,
            0, 2, 2, 0, 1, 3, 1, 0
        ]
    )
}
