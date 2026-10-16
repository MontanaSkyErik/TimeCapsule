import SwiftUI

/// The five coloured bands from the sketches, with content placed by band. Sizes inside are
/// given for a 390 pt wide screen and multiplied by `layout.u`, so the same page looks the same
/// on the phone and at 1080 x 1920 on the projector.
struct Bands<Content: View>: View {
    @ViewBuilder var content: (BandLayout) -> Content

    var body: some View {
        GeometryReader { geo in
            let layout = BandLayout(size: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(Theme.bands.indices, id: \.self) { i in
                    Theme.bands[i]
                        .frame(width: geo.size.width, height: layout.rect(i).height)
                        .offset(y: layout.rect(i).minY)
                }
                content(layout)
            }
        }
    }
}

struct BandLayout {
    let size: CGSize

    /// One design point.
    var u: CGFloat { size.width / 390 }

    func rect(_ index: Int) -> CGRect {
        let total = Theme.bandWeights.reduce(0, +)
        let top = Theme.bandWeights.prefix(index).reduce(0, +) / total * size.height
        let height = Theme.bandWeights[index] / total * size.height
        return CGRect(x: 0, y: top, width: size.width, height: height)
    }

    /// The area from the top of band `from` to the bottom of band `to`.
    func rect(_ from: Int, _ to: Int) -> CGRect { rect(from).union(rect(to)) }
}

extension View {
    func place(in rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height).offset(x: rect.minX, y: rect.minY)
    }
}
