import SwiftUI

struct LandingPetBadge: View {
    let sheet: PetSpriteSheet
    var isAttentive: Bool = false
    var attentionLevel: CGFloat = 1.0
    var hintPulse: Bool = false
    var introBounce: Bool = false
    var blinkPause: Bool = false
    var sideEyeShift: Bool = false
    var curiousTilt: Bool = false

    var body: some View {
        PetSpriteView(sheet: sheet, scale: 0.16, animationDuration: 0.22, blinkPause: blinkPause)
            .scaleEffect(curiousTilt ? 1.018 : (introBounce ? 1.03 : (isAttentive ? 0.975 : 1.0)))
            .rotationEffect(.degrees(
                curiousTilt ? -4.0 :
                (introBounce ? -1.0 :
                    (isAttentive ? Double(3.4 * attentionLevel) + (hintPulse ? 0.35 : 0) : (hintPulse ? 0.25 : 0)))
            ))
            .offset(
                x: curiousTilt ? -1.2 : (introBounce ? 0 : (
                    isAttentive
                    ? CGFloat(4.5 * attentionLevel) + (sideEyeShift ? 1.8 : 0)
                    : (hintPulse ? 0.8 : 0)
                )),
                y: curiousTilt ? -0.8 : (introBounce ? -2 : (isAttentive ? CGFloat(1.5 * attentionLevel) : (hintPulse ? -0.8 : 0)))
            )
            .animation(.easeInOut(duration: 0.55), value: isAttentive)
            .animation(.easeInOut(duration: 1.15), value: hintPulse)
            .animation(.easeOut(duration: 0.85), value: introBounce)
            .animation(.easeInOut(duration: 0.45), value: sideEyeShift)
            .animation(.easeInOut(duration: 0.32), value: curiousTilt)
            .padding(.top, 1)
            .padding(.bottom, 2)
            .padding(.leading, 2)
            .padding(.trailing, 2)
    }
}
