import Foundation

enum PropertyType : String {
    case Bool = "bool"
    case Color = "color"
    case Int = "int"
    case File = "file"
    case Float = "float"
    case Object = "object"
    case String = "string"
}

class PEMTmxProperty : NSObject {
    private (set) var name : String
    private (set) var type = PropertyType.String
    private (set) var value : String

    init?(attributes: Dictionary<String, String>) {
        guard let propertyName = attributes[ElementAttributes.Name.rawValue] else { return nil }
        guard let propertyValue = attributes[ElementAttributes.Value.rawValue] else { return nil }
        name = propertyName
        value = propertyValue
        
        super.init()
        
        if let value = attributes[ElementAttributes.TypeAttribute.rawValue] {
            if let propertyType = PropertyType(rawValue: value) {
                type = propertyType
            } else {
                #if DEBUG
                print("PEMTmxProperty: unsupported property type: \(String(describing: value))")
                #endif
            }
        }
    }
    
    deinit {
        #if DEBUG
        #if os(macOS)
        print("deinit: \(self.className.components(separatedBy: ".").last! )")
        #else
        print("deinit: \(type(of: self))")
        #endif
        #endif
    }
    
    // MARK: - Debug

    #if DEBUG
    override var description: String {
        return "PEMTmxProperty: name: \(name), (type: \(type), value: \(value))"
    }
    #endif
}
