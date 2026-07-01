import RealityKit
import UIKit

public extension Entity {
    /// Recursively replaces all materials on `ModelEntity` descendants with an unlit
    /// hologram tint (alpha taken from `color`).
    func applyHologramMaterial(color: UIColor) {
        if let model = self as? ModelEntity {
            var mat = UnlitMaterial(color: color)
            let alpha = color.cgColor.alpha
            mat.blending = .transparent(opacity: .init(floatLiteral: Float(alpha)))
            model.model?.materials = [mat]
        }
        for child in children {
            child.applyHologramMaterial(color: color)
        }
    }
}
