import Foundation

// MARK: - TMX

func tileAttributes(fromId id: UInt32) -> (id: UInt32, flippedHorizontally: Bool, flippedVertically: Bool, flippedDiagonally: Bool) {
    let flippedDiagonalFlag: UInt32   = 0x20000000
    let flippedVerticalFlag: UInt32   = 0x40000000
    let flippedHorizontalFlag: UInt32 = 0x80000000

    let flippedAll = (flippedHorizontalFlag | flippedVerticalFlag | flippedDiagonalFlag)
    let flippedMask = ~(flippedAll)

    let flippedHorizontally: Bool = (id & flippedHorizontalFlag) != 0
    let flippedVertically: Bool = (id & flippedVerticalFlag) != 0
    let flippedDiagonally: Bool = (id & flippedDiagonalFlag) != 0

    let id = id & flippedMask
    return (id, flippedHorizontally, flippedVertically, flippedDiagonally)
}

// MARK: - Files

func bundlePathForResource(_ resource: String) -> String? {
    var fileName = resource
    var fileExtension : String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.path(forResource: fileName, ofType: fileExtension)
}

func bundleURLForResource(_ resource: String) -> URL? {
    var fileName = resource
    var fileExtension : String?

    if resource.range(of: ".") != nil {
        fileName = (resource as NSString).deletingPathExtension
        fileExtension = (resource as NSString).pathExtension
    }

    return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
}
