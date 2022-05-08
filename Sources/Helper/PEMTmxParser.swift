internal enum MapElements : String {
    case None = "none"
    case Map = "map"
    case TileSet = "tileset"
    case Image = "image"
    case Layer = "layer"
    case ObjectGroup = "objectgroup"
    case ImageLayer = "imagelayer"
    case Group = "group"
    case Properties = "properties"
    case Template = "template"
}

internal enum ElementAttributes : String {
    case BackgroundColor = "backgroundcolor"
    case Columns = "columns"
    //case CompressionLevel = "compressionlevel"
    case FirstGid = "firstgid"
//    case Format = "format"
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
    case Trans = "trans"
    case Version = "version"
    case Width = "width"
}

extension PEMTmxMap {
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
        case MapElements.Map.rawValue:
            currentMapElement = .Map
            getAttributes(attributeDict)
            currentMapElement = .Map
        case MapElements.TileSet.rawValue :
            currentMapElement = .TileSet
            if let value = attributeDict[ElementAttributes.Source.rawValue] {
                #if DEBUG
                print("PEMTmxMap: external tilesets are unsupported: \(value)")
                #endif
                parser.abortParsing()
                return
            }
            
            var gId = UInt(0)
            if let value = attributeDict[ElementAttributes.FirstGid.rawValue] {
                if currentFirstGid == 0 {
                    gId = UInt(value) ?? 0
                } else {
                    gId = currentFirstGid
                    currentFirstGid = 0
                }
            }
            
            let tileSet = PEMTmxTileSet(gId: gId, attributes: attributeDict)
            tileSets.append(tileSet)
        case MapElements.Image.rawValue:
            switch currentMapElement {
            case .TileSet:
                if let tileSet = tileSets.last {
                    tileSet.setTileSetImage(attributes: attributeDict)
                }
            default:
                #if DEBUG
                print("PEMTmxMap: unexpected XML element name: <\(elementName)> as child of <\(currentMapElement.rawValue)>")
                #endif
            }
        case MapElements.Layer.rawValue:
            break
        case MapElements.ObjectGroup.rawValue:
            break
        case MapElements.ImageLayer.rawValue:
            break
        case MapElements.Group.rawValue:
            break
        case MapElements.Properties.rawValue:
            break
        case MapElements.Template.rawValue:
            break

        default:
            #if DEBUG
            print("PEMTmxMap: unsupported XML element name: <\(elementName)>")
            #endif
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName {
        case MapElements.Map.rawValue:
            currentMapElement = .None
        case MapElements.TileSet.rawValue :
            currentMapElement = .None
        case MapElements.Image.rawValue:
            break
        case MapElements.Layer.rawValue:
            break
        case MapElements.ObjectGroup.rawValue:
            break
        case MapElements.ImageLayer.rawValue:
            break
        case MapElements.Group.rawValue:
            break
        case MapElements.Properties.rawValue:
            break
        case MapElements.Template.rawValue:
            break
        default:
            #if DEBUG
            print("PEMTmxMap: unsupported XML element name: <\(elementName)>")
            #endif
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentParseString += string
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        #if DEBUG
        print("PEMTmxMap: parseErrorOccurred: \(parseError)")
        #endif
    }
}
