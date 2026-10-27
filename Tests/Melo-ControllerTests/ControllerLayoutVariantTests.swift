import CoreGraphics
import Testing
@testable import Melo_Controller

struct ControllerLayoutVariantTests {
    private static func variant(_ pane: CGSize, _ scale: CGFloat, stickButtons: Bool, foldWidth: CGFloat) -> ControllerLayoutVariant {
        ControllerLayoutVariant(paneSize: pane, controllerScale: scale, stickButtons: stickButtons, foldWidth: foldWidth)
    }

    @Test(
        "The spread size cap fits, and the next whole percent does not",
        arguments: [
            (CGSize(width: 678, height: 466), false, CGFloat(0)),
            (CGSize(width: 678, height: 466), true, CGFloat(0)),
            (CGSize(width: 638, height: 466), false, CGFloat(0)),
            (CGSize(width: 951, height: 449), true, CGFloat(0)),
            (CGSize(width: 951, height: 449), true, CGFloat(40)),
        ]
    )
    func spreadCapIsTheLargestFit(pane: CGSize, stickButtons: Bool, foldWidth: CGFloat) throws {
        let sizes = ControllerPlacement.scaleRange
        let cap = try #require(ControllerLayoutVariant.largestSpreadScale(
            in: sizes, paneSize: pane, stickButtons: stickButtons, foldWidth: foldWidth
        ))
        #expect(Self.variant(pane, cap, stickButtons: stickButtons, foldWidth: foldWidth) == .landscape)
        #expect(cap < sizes.upperBound)
        let nextPercent = ((cap * 100).rounded() + 1) / 100
        #expect(Self.variant(pane, nextPercent, stickButtons: stickButtons, foldWidth: foldWidth) == .portrait)
    }

    @Test("An edge on a whole percent is the cap itself")
    func spreadCapReachesAnExactEdge() {
        // 320 x 1.5 + 200 = 680, so 1.5 fits exactly.
        let cap = ControllerLayoutVariant.largestSpreadScale(
            in: ControllerPlacement.scaleRange,
            paneSize: CGSize(width: 680, height: 400),
            stickButtons: false,
            foldWidth: 0
        )
        #expect(cap == 1.5)
    }

    @Test("A pane that fits the spread arrangement at every size is not capped")
    func wideSpreadPaneIsNotCapped() {
        let cap = ControllerLayoutVariant.largestSpreadScale(
            in: ControllerPlacement.scaleRange,
            paneSize: CGSize(width: 951, height: 449),
            stickButtons: false,
            foldWidth: 0
        )
        #expect(cap == ControllerPlacement.scaleRange.upperBound)
    }

    @Test("A pane too narrow for the spread arrangement has no cap")
    func narrowPaneHasNoSpreadCap() {
        let cap = ControllerLayoutVariant.largestSpreadScale(
            in: ControllerPlacement.scaleRange,
            paneSize: CGSize(width: 466, height: 300),
            stickButtons: false,
            foldWidth: 0
        )
        #expect(cap == nil)
    }

    @Test("The compact height grows with the size and with the stick buttons")
    func compactHeight() {
        #expect(ControllerLayoutVariant.compactHeight(controllerScale: 1, stickButtons: false) == 282)
        #expect(ControllerLayoutVariant.compactHeight(controllerScale: 1, stickButtons: true) == 324)
        // Below size 1 the stick keeps its 160 pt frame.
        #expect(ControllerLayoutVariant.compactHeight(controllerScale: 0.5, stickButtons: false) == 254.5)
        #expect(ControllerLayoutVariant.compactHeight(controllerScale: 2, stickButtons: false) == 467)
    }
}
