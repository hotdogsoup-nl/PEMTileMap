import Foundation

enum PropertyType : String {
    case bool = "bool"
    case color = "color"
    case int = "int"
    case file = "file"
    case float = "float"
    case object = "object"
    case string = "string"
}

class PEMTmxProperty : NSObject {
    private (set) var name : String
    private (set) var type = PropertyType.string
    private (set) var value : String

    init?(attributes: Dictionary<String, String>) {
        guard let propertyName = attributes[ElementAttributes.name.rawValue] else { return nil }
        guard let propertyValue = attributes[ElementAttributes.value.rawValue] else { return nil }
        name = propertyName
        value = propertyValue
        
        super.init()
        
        if let value = attributes[ElementAttributes.typeAttribute.rawValue] {
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
