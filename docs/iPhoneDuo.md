# iPhone Duo support

DolphiniOS links the iOS 27.1 or later SDK to opt into native iPhone Duo screen sizing and adaptive system bars. The app remains an iPhone and iPad app (`TARGETED_DEVICE_FAMILY = "1,2"`); iPhone Duo does not use a separate device family or Info.plist capability.

The software library sizes its grid from the collection view's current safe area instead of assuming a fixed phone width. During emulation, a `UIArrangementViewController` uses an overlay arrangement: the touch controls overlay the renderer on a flat display, then the renderer and controls move to opposite sides of an active fold. The renderer fills its assigned panel; safe areas and camera reserved regions constrain interactive controls, not the game image. This avoids excluding a full-height strip beside a camera. On iOS versions before 27.1, the same views use the existing overlay layout.

Emulation actions use `UINavigationItem` bar button items in `UINavigationController`, allowing UIKit to place them in the native Duo sidebar. The bar has a transparent appearance and the game extends beneath it; no custom side-button stack is used. The reveal button stays at the top-left of the controls safe area.

The renderer follows its current window scene and display scale. It resizes without restarting emulation when the app moves between the outer and inner displays, changes pose, enters Split View, or moves to an external display.

## Validation

Use Xcode 27.1 or later and the iPhone Duo simulator in Device Hub. Verify all of the following while a game remains running:

- closed outer display in portrait and landscape
- fully open inner display in portrait and landscape
- book and tabletop folds, including continuous transitions into and out of each pose
- Split View on both the leading and trailing side
- active camera occlusion
- touch controls, Wii IR pointer, motion input, and the virtual controller
- navigation bar visibility and all emulation menu actions
- external-display connection and disconnection

Also test a non-Duo compact iPhone and a regular-width iPad to cover the fallback layout.
