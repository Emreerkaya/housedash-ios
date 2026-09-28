import CoreGraphics

public enum HDSpacing {
    public static let item: CGFloat = 8
    public static let group: CGFloat = 24
    public static let margin: CGFloat = 20

    public static let minimumGroupToItemRatio: CGFloat = 2.5

    public static var groupToItemRatio: CGFloat {
        group / item
    }
}
