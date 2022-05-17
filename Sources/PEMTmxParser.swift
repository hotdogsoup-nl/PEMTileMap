import Foundation

enum Elements : String {
    case None
    case Animation = "animation"
    case Data = "data"
    case Frame = "frame"
    case Group = "group"
    case Image = "image"
    case ImageLayer = "imagelayer"
    case Layer = "layer"
    case Map = "map"
    case ObjectGroup = "objectgroup"
    case Properties = "properties"
    case Property = "property"
    case Template = "template"
    case Tile = "tile"
    case TileOffset = "tileoffset"
    case TileSet = "tileset"
}

enum ElementAttributes : String {
    case BackgroundColor = "backgroundcolor"
    case Columns = "columns"
    case Compression = "compression"
    case CompressionLevel = "compressionlevel"
    case Duration = "duration"
    case Encoding = "encoding"
    case FirstGid = "firstgid"
    case Format = "format"
    case Height = "height"
    case HexSideLength = "hexsidelength"
    case Id = "id"
    case Infinite = "infinite"
    case Margin = "margin"
    case Name = "name"
    case NextLayerId = "nextlayerid"
    case NextObjectId = "nextobjectid"
    case ObjectAlignment = "objectalignment"
    case OffsetX = "offsetx"
    case OffsetY = "offsety"
    case Orientation = "orientation"
    case Opacity = "opacity"
    case ParallaxX = "parallaxx"
    case ParallaxY = "parallaxy"
    case ParallaxOriginX = "parallaxoriginx"
    case ParallaxOriginY = "parallaxoriginy"
    case Probability = "probability"
    case Propertytype = "propertytype"
    case RenderOrder = "renderorder"
    case RepeatX = "repeatx"
    case RepeatY = "repeaty"
    case Rows = "rows"
    case Source = "source"
    case Spacing = "spacing"
    case StaggerAxis = "staggeraxis"
    case StaggerIndex = "staggerindex"
    case TileCount = "tilecount"
    case TileId = "tileid"
    case TiledVersion = "tiledversion"
    case TileHeight = "tileheight"
    case TileWidth = "tilewidth"
    case TintColor = "tintcolor"
    case Trans = "trans"
    case TypeAttribute = "type" // "Type" is a reserved MetaType name so we use "TypeAttribute" instead
    case Value = "value"
    case Version = "version"
    case Visible = "visible"
    case Width = "width"
    case X = "x"
    case Y = "y"
}

protocol PEMTmxPropertiesProtocol {
    func addProperties(_ newProperties: [PEMTmxProperty])
}

class PEMTmxParser : XMLParser, XMLParserDelegate {
    enum DataEncoding : String {
        case Base64 = "base64"
        case Csv = "csv"
    }

    enum DataCompression : String {
        case None
        case Gzip = "gzip"
        case Zlib = "zlib"
        case Zstd = "zstd"
    }
    
    enum ParseFileType {
        case Tmx
        case Tsx
    }
    
    private weak var currentMap : PEMTmxMap?
    private weak var currentTileSet : PEMTmxTileSet?

    private var currentFileType : ParseFileType
    private var currentProperties : [PEMTmxProperty]?
    private var currentParseString : String = ""
    private var elementPath : [AnyObject] = []
    private var dataEncoding : DataEncoding?
    private var dataCompression = DataCompression.None
    
    // MARK: - Init
    
    init?(map: PEMTmxMap, fileURL: URL) {
        currentFileType = .Tmx
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
        currentFileType = .Tsx
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
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
            
        // top level elements
        case Elements.Map.rawValue:
            currentMap?.addAttributes(attributeDict)
            elementPath.append(currentMap!)
        case Elements.TileSet.rawValue :
            switch currentFileType {
            case .Tmx:
                if let tileSet = PEMTmxTileSet(attributes: attributeDict) {
                    currentMap?.tileSets.append(tileSet)
                    elementPath.append(tileSet)
                }
            case .Tsx:
                currentTileSet?.addAttributes(attributeDict)
                elementPath.append(currentTileSet!)
            }
        case Elements.Layer.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            let layer = PEMTmxLayer(attributes: attributeDict, group:currentGroup)
            currentMap?.layers.append(layer)
            elementPath.append(layer)
        case Elements.ObjectGroup.rawValue:
            break
        case Elements.ImageLayer.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            let layer = PEMTmxImageLayer(attributes: attributeDict, group:currentGroup)
            currentMap?.layers.append(layer)
            elementPath.append(layer)
        case Elements.Group.rawValue:
            let currentGroup = elementPath.last as? PEMTmxGroup
            if let group = PEMTmxGroup(attributes: attributeDict, group:currentGroup) {
                elementPath.append(group)
            }
        case Elements.Properties.rawValue:
            currentProperties = []
        case Elements.Template.rawValue:
            break

        // child elements
        case Elements.Image.rawValue:
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
        case Elements.Tile.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileSet {
                if let tileData = currentElement.addOrUpdateTileData(attributes: attributeDict) {
                    elementPath.append(tileData)
                }
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.Animation.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileData {
                if let animation = currentElement.addAnimation() {
                    elementPath.append(animation)
                }
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.Frame.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileAnimation {
                currentElement.addAnimationFrame(attributes: attributeDict)
                break
            }
            abortWithUnexpected(elementName: elementName, inside: elementPath.last)
        case Elements.Data.rawValue:
            if let value = attributeDict[ElementAttributes.Encoding.rawValue] {
                if let encoding = DataEncoding(rawValue: value) {
                    dataEncoding = encoding
                } else {
                    #if DEBUG
                    print("PEMTmxParser: unsupported data encoding: \(String(describing: value))")
                    #endif
                    parser.abortParsing()
                }
            }
            
            if let value = attributeDict[ElementAttributes.Compression.rawValue] {
                if let compression = DataCompression(rawValue: value) {
                    dataCompression = compression
                } else {
                    dataCompression = .None
                }
            }
        case Elements.Property.rawValue:
            if let property = PEMTmxProperty(attributes: attributeDict) {
                currentProperties?.append(property)
            }
        case Elements.TileOffset.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileSet {
                currentElement.setTileOffset(attributes: attributeDict)
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
        case Elements.Map.rawValue:
            if elementPath.last is PEMTmxMap {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.TileSet.rawValue :
            if elementPath.last is PEMTmxTileSet {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.Layer.rawValue:
            if elementPath.last is PEMTmxLayer {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.ObjectGroup.rawValue:
            break
        case Elements.ImageLayer.rawValue:
            if elementPath.last is PEMTmxImageLayer {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.Group.rawValue:
            if elementPath.last is PEMTmxGroup {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.Properties.rawValue:
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
        case Elements.Template.rawValue:
            break
            
        // child elements
        case Elements.Image.rawValue:
            break
        case Elements.Tile.rawValue:
            if elementPath.last is PEMTmxTileData {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.Animation.rawValue:
            if elementPath.last is PEMTmxTileAnimation {
                elementPath.removeLast()
                break
            }
            abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
        case Elements.Frame.rawValue:
            break
        case Elements.Data.rawValue:
            guard let tileLayer = currentMap?.layers.last as? PEMTmxLayer else {
                abortWithUnexpected(closingElementName: elementName, inside: elementPath.last)
                break
            }
            
            var decodedData : [UInt32]?
            switch dataEncoding {
            case .Base64:
                decodedData = decodeData(base64: currentParseString, compression: dataCompression)
                break
            case .Csv:
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
        case Elements.Property.rawValue:
            break
        case Elements.TileOffset.rawValue:
            break
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
    
    private func decodeData(base64 data: String, compression: DataCompression = .None) -> [UInt32]? {
        guard let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) else {
            #if DEBUG
            print("PEMTmxParser: data is not base64 encoded.")
            #endif
            return nil
        }
        
        switch compression {
            case .Zlib, .Gzip:
                if let decompressed = try? decodedData.gunzipped() {
                    return decompressed.toArray(type: UInt32.self)
                }
            case .Zstd:
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
