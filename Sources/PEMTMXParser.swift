internal enum MapElements : String {
    case None = "none"
    case Map = "map"
    case TileSet = "tileset"
    case Layer = "layer"
    case ObjectGroup = "objectgroup"
    case ImageLayer = "imagelayer"
    case Group = "group"
    case Properties = "properties"
    case Template = "template"
}

internal enum MapAttributes : String {
    case BackgroundColor = "backgroundcolor"
    case Columns = "columns"
    //case CompressionLevel = "compressionlevel"
    case FirstGid = "firstgid"
    case Height = "height"
    case HexSideLength = "hexsidelength"
    case Infinite = "infinite"
    case Margin = "margin"
    case Name = "name"
    //case NextLayerId = "nextlayerid"
    //case NextObjectId = "nextobjectid"
    case ObjectAlignment = "objectalignment"
    case Orientation = "orientation"
    case ParallaxOriginX = "parallaxoriginx"
    case ParallaxOriginY = "parallaxoriginy"
    case RenderOrder = "renderorder"
    case Rows = "rows"
    case Source = "source"
    case Spacing = "spacing"
    case StaggerAxis = "staggeraxis"
    case StaggerIndex = "staggerindex"
    case TileCount = "tilecount"
    case TiledVersion = "tiledversion"
    case TileHeight = "tileheight"
    case TileWidth = "tilewidth"
    case Version = "version"
    case Width = "width"
}

extension PEMTMXMap {    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
        case MapElements.Map.rawValue:
            getAttributes(attributeDict)
        case MapElements.TileSet.rawValue :
            if let value = attributeDict[MapAttributes.Source.rawValue] {
                #if DEBUG
                print("PEMTMXMap: external tilesets unsupported: \(value)")
                #endif
                parser.abortParsing()
                return
            }
            
            var gId = UInt(0)
            if let value = attributeDict[MapAttributes.FirstGid.rawValue] {
                if currentFirstGid == 0 {
                    gId = UInt(value) ?? 0
                } else {
                    gId = currentFirstGid
                    currentFirstGid = 0
                }
            }
            
            let tileSet = PEMTMXTileSet(gId: gId, attributes: attributeDict)
            tileSets.append(tileSet)
        default:
            #if DEBUG
            print("PEMTMXMap: unsupported XML element name: \(elementName)")
            #endif
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName {
        default:
            #if DEBUG
            print("PEMTMXMap: unsupported XML element name: \(elementName)")
            #endif
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentParseString += string
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        #if DEBUG
        print("PEMTMXMap: parseErrorOccurred: \(parseError)")
        #endif
    }
}
