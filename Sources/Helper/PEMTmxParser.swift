import Foundation

enum Elements: String {
    case none
    case animation = "animation"
    case data = "data"
    case ellipse = "ellipse"
    case frame = "frame"
    case group = "group"
    case image = "image"
    case imageLayer = "imagelayer"
    case layer = "layer"
    case map = "map"
    case object = "object"
    case objectGroup = "objectgroup"
    case point = "point"
    case polygon = "polygon"
    case polyline = "polyline"
    case properties = "properties"
    case property = "property"
    case template = "template"
    case text = "text"
    case tile = "tile"
    case tileOffset = "tileoffset"
    case tileSet = "tileset"
}

enum ElementAttributes: String {
    case backgroundColor = "backgroundcolor"
    case bold = "bold"
    case columns = "columns"
    case color = "color"
    case compression = "compression"
    case compressionLevel = "compressionlevel"
    case drawOrder = "draworder"
    case duration = "duration"
    case encoding = "encoding"
    case firstGid = "firstgid"
    case fontFamily = "fontfamily"
    case format = "format"
    case gid = "gid"
    case hAlign = "halign"
    case height = "height"
    case hexSideLength = "hexsidelength"
    case id = "id"
    case infinite = "infinite"
    case italic = "italic"
    case kerning = "kerning"
    case margin = "margin"
    case name = "name"
    case nextLayerId = "nextlayerid"
    case nextObjectId = "nextobjectid"
    case objectAlignment = "objectalignment"
    case offsetX = "offsetx"
    case offsetY = "offsety"
    case orientation = "orientation"
    case opacity = "opacity"
    case parallaxX = "parallaxx"
    case parallaxY = "parallaxy"
    case parallaxOriginX = "parallaxoriginx"
    case parallaxOriginY = "parallaxoriginy"
    case pixelSize = "pixelsize"
    case points = "points"
    case probability = "probability"
    case propertytype = "propertytype"
    case renderOrder = "renderorder"
    case repeatX = "repeatx"
    case repeatY = "repeaty"
    case rotation = "rotation"
    case rows = "rows"
    case source = "source"
    case spacing = "spacing"
    case staggerAxis = "staggeraxis"
    case staggerIndex = "staggerindex"
    case strikeout = "strikeout"
    case tileCount = "tilecount"
    case tileId = "tileid"
    case tiledVersion = "tiledversion"
    case tileHeight = "tileheight"
    case tileWidth = "tilewidth"
    case tintColor = "tintcolor"
    case trans = "trans"
    case typeAttribute = "type" // "Type" is a reserved MetaType name so we use "TypeAttribute" instead
    case underline = "underline"
    case vAlign = "valign"
    case value = "value"
    case version = "version"
    case visible = "visible"
    case width = "width"
    case wrap = "wrap"
    case x = "x"
    case y = "y"
}

protocol PEMTmxPropertiesProtocol {
    func addProperties(_ newProperties: [PEMTmxProperty])
}

class PEMTmxParser: XMLParser, XMLParserDelegate {
    enum DataEncoding: String {
        case base64 = "base64"
        case csv = "csv"
    }

    enum DataCompression: String {
        case none
        case gzip = "gzip"
        case zlib = "zlib"
        case zstd = "zstd"
    }
    
    enum ParseFileType {
        case tmx
        case tsx
    }
    
    private weak var currentMap: PEMTmxMap?
    private weak var currentTileSet: PEMTmxTileSet?

    private var currentFileType: ParseFileType
    private var currentProperties: [PEMTmxProperty]?
    private var currentParseString: String = ""
    private var elementPath: [AnyObject] = []
    private var dataEncoding: DataEncoding?
    private var dataCompression = DataCompression.none
    
    // MARK: - Init
    
    init?(map: PEMTmxMap, fileURL: URL) {
        currentFileType = .tmx
        currentMap = map

        do {
            let data = try Data(contentsOf:fileURL)
            super.init(data: data)
        }
        catch {
            return nil
        }

        delegate = self
        shouldProcessNamespaces = false
        shouldReportNamespacePrefixes = false
        shouldResolveExternalEntities = false        
    }
    
    init?(tileSet: PEMTmxTileSet, fileURL: URL) {
        currentFileType = .tsx
        currentTileSet = tileSet

        do {
            let data = try Data(contentsOf:fileURL)
            super.init(data: data)
        }
        catch {
            return nil
        }

        delegate = self
        shouldProcessNamespaces = false
        shouldReportNamespacePrefixes = false
        shouldResolveExternalEntities = false
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
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(_ parser: XMLParser) {
        elementPath.removeAll()
        currentParseString.removeAll()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
            
        // top level elements
        case Elements.map.rawValue:
            currentMap?.addAttributes(attributeDict)
            elementPath.append(currentMap!)
        case Elements.tileSet.rawValue :
            switch currentFileType {
            case .tmx:
                if let tileSet = PEMTmxTileSet(attributes: attributeDict) {
                    currentMap?.tileSets.append(tileSet)
                    elementPath.append(tileSet)
                }
            case .tsx:
                currentTileSet?.addAttributes(attributeDict)
                elementPath.append(currentTileSet!)
            }
        case Elements.layer.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            if let tileLayer = PEMTmxTileLayer(attributes: attributeDict, group:currentGroup) {
                currentMap?.layers.append(tileLayer)
                elementPath.append(tileLayer)
            }
        case Elements.objectGroup.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            if let groupLayer = PEMTmxObjectGroup(attributes: attributeDict, group:currentGroup) {
                currentMap?.layers.append(groupLayer)
                elementPath.append(groupLayer)
            }
            break
        case Elements.imageLayer.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            let layer = PEMTmxImageLayer(attributes: attributeDict, group:currentGroup)
            currentMap?.layers.append(layer)
            elementPath.append(layer)
        case Elements.group.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            if let group = PEMTmxGroup(attributes: attributeDict, group:currentGroup) {
                elementPath.append(group)
            }
        case Elements.properties.rawValue:
            currentProperties = []
        case Elements.template.rawValue:
            break

        // child elements
        case Elements.image.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileSet {
                currentElement.setSpriteSheetImage(attributes: attributeDict)
                break
            }
            
            if let currentElement = elementPath.last as? PEMTmxTileData {
                currentElement.addTileImage(attributes: attributeDict)
                break
            }

            if let currentElement = elementPath.last as? PEMTmxImageLayer {
                currentElement.setImage(attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.tile.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileSet {
                if let tileData = currentElement.addOrUpdateTileData(attributes: attributeDict) {
                    elementPath.append(tileData)
                }
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.animation.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileData {
                if let animation = currentElement.addAnimation() {
                    elementPath.append(animation)
                }
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.frame.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileAnimation {
                currentElement.addAnimationFrame(attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.data.rawValue:
            currentParseString.removeAll()

            if let value = attributeDict[ElementAttributes.encoding.rawValue] {
                if let encoding = DataEncoding(rawValue: value) {
                    dataEncoding = encoding
                } else {
                    #if DEBUG
                    print("PEMTmxParser: unsupported data encoding: \(String(describing: value))")
                    #endif
                    parser.abortParsing()
                }
            }
            
            if let value = attributeDict[ElementAttributes.compression.rawValue] {
                if let compression = DataCompression(rawValue: value) {
                    dataCompression = compression
                } else {
                    dataCompression = .none
                }
            }
        case Elements.property.rawValue:
            currentParseString.removeAll()
            if let property = PEMTmxProperty(attributes: attributeDict) {
                currentProperties?.append(property)
                elementPath.append(property)
            }
        case Elements.tileOffset.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileSet {
                currentElement.setTileOffset(attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.object.rawValue:
            if let currentElement = elementPath.last as? PEMTmxObjectGroup {
                if let objectData = currentElement.addObjectData(attributes: attributeDict) {
                    elementPath.append(objectData)
                }
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.ellipse.rawValue:
            if let currentElement = elementPath.last as? PEMTmxObjectData {
                currentElement.setObjectType(.ellipse)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.point.rawValue:
            if let currentElement = elementPath.last as? PEMTmxObjectData {
                currentElement.setObjectType(.point)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.polygon.rawValue:
            if let currentElement = elementPath.last as? PEMTmxObjectData {
                currentElement.setObjectType(.polygon, attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.polyline.rawValue:
            if let currentElement = elementPath.last as? PEMTmxObjectData {
                currentElement.setObjectType(.polyline, attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.text.rawValue:
            currentParseString.removeAll()

            if let currentElement = elementPath.last as? PEMTmxObjectData {
                currentElement.setObjectType(.text, attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        default:
            #if DEBUG
            print("PEMTmxParser: unsupported TMX element name: <\(elementName)>")
            #endif
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
            
        // top level elements
        case Elements.map.rawValue:
            if elementPath.last is PEMTmxMap {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.tileSet.rawValue :
            if elementPath.last is PEMTmxTileSet {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.layer.rawValue:
            if elementPath.last is PEMTmxTileLayer {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.objectGroup.rawValue:
            if elementPath.last is PEMTmxObjectGroup {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.imageLayer.rawValue:
            if elementPath.last is PEMTmxImageLayer {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.group.rawValue:
            if elementPath.last is PEMTmxGroup {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.properties.rawValue:
            if currentProperties == nil {
                break
            }
            if let currentElement = elementPath.last as? PEMTmxPropertiesProtocol {
                currentElement.addProperties(currentProperties!)
                currentProperties = nil
                break
            }
            #if DEBUG
            print("PEMTmxParser: properties protocol not implemented on: \(String(describing: elementPath.last))")
            #endif
            currentProperties = nil
        case Elements.template.rawValue:
            break
            
        // child elements
        case Elements.image.rawValue:
            break
        case Elements.tile.rawValue:
            if elementPath.last is PEMTmxTileData {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.animation.rawValue:
            if elementPath.last is PEMTmxTileAnimation {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.frame.rawValue:
            break
        case Elements.data.rawValue:
            guard let tileLayer = currentMap?.layers.last as? PEMTmxTileLayer else {
                abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
                break
            }
            
            var decodedData : [UInt32]?
            switch dataEncoding {
            case .base64:
                decodedData = decodeData(base64: currentParseString, compression: dataCompression)
                break
            case .csv:
                decodedData = decodeData(csv: currentParseString)
            default:
                break
            }
            
            if decodedData != nil {
                for id in decodedData! {
                    tileLayer.tileData.append(id)
                }
            } else {
                #if DEBUG
                print("PEMTmxParser: could not decode layer data for layer: \(tileLayer))")
                #endif
                parser.abortParsing()
            }
        case Elements.property.rawValue:
            if let currentElement = elementPath.last as? PEMTmxProperty {
                if currentParseString.count > 0 && currentElement.type == .string {
                    currentElement.setValue(currentParseString)
                }
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.tileOffset.rawValue:
            break
        case Elements.object.rawValue:
            if elementPath.last is PEMTmxObjectData {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.ellipse.rawValue:
            break
        case Elements.point.rawValue:
            break
        case Elements.polygon.rawValue:
            break
        case Elements.polyline.rawValue:
            break
        case Elements.text.rawValue:
            if let currentElement = elementPath.last as? PEMTmxObjectData {
                currentElement.setText(currentParseString)
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
            currentParseString.removeAll()
        default:
            #if DEBUG
            print("PEMTmxParser: unsupported TMX element name: <\(elementName)>")
            #endif
        }
        
        currentParseString.removeAll()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentParseString += string
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        #if DEBUG
        print("PEMTmxParser: parseErrorOccurred: \(parseError)")
        #endif
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        elementPath.removeAll()
        currentParseString.removeAll()
    }
    
    private func abortWithUnexpected(closingElementName: String, inside element: AnyObject?) {
        #if DEBUG
        print("PEMTmxParser: unexpected closing element: <\(closingElementName)> current element: \(String(describing: element)).")
        #endif
        abortParsing()
    }
    
    private func abortWithUnexpected(elementName: String, inside element: AnyObject?) {
        #if DEBUG
        print("PEMTmxParser: unexpected <\(elementName)> inside \(String(describing: element)).")
        #endif
        abortParsing()
    }
    
    // MARK: - Decoding data

    private func decodeData(csv data: String) -> [UInt32] {
        return cleanString(data).components(separatedBy: ",").map {UInt32($0)!}
    }
    
    private func cleanString(_ string: String) -> String {
        var result = string.replacingOccurrences(of: "\n", with: "")
        result = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return result.replacingOccurrences(of: " ", with: "")
    }
    
    private func decodeData(base64 data: String, compression: DataCompression = .none) -> [UInt32]? {
        guard let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) else {
            #if DEBUG
            print("PEMTmxParser: data is not base64 encoded.")
            #endif
            return nil
        }
        
        switch compression {
            case .zlib, .gzip:
                if let decompressed = try? decodedData.gunzipped() {
                    return decompressed.toArray(type: UInt32.self)
                }
            case .zstd:
                #if DEBUG
                print("PEMTmxParser: zstd compression is not supported.")
                #endif
                return nil
            default:
                return decodedData.toArray(type: UInt32.self)
        }
        
        return nil
    }
}
