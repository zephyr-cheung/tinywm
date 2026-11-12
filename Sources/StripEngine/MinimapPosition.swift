/// Where the strip minimap sits on the screen it appears on.
public enum MinimapPosition: String, Codable, Sendable, CaseIterable {
    /// The bottom edge, above the Dock. The shipped place.
    case bottom
    /// The middle of the screen, over the focused windows.
    case middle
    /// The top edge, under the menu bar.
    case top
}
