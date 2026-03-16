import Testing
@testable import PirratesDesignSystem

struct DesignSystemTests {
    @Test
    func themeColorsExist() {
        _ = AppTheme.background
        _ = AppTheme.accent
    }
}
