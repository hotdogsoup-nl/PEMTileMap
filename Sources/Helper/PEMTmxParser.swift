internal enum MapElements : String {
    case Group = "group"
    case Image = "image"
    case ImageLayer = "imagelayer"
    case Layer = "layer"
    case Map = "map"
    case None = "none"
    case ObjectGroup = "objectgroup"
    case Properties = "properties"
    case Template = "template"
    case TileSet = "tileset"
}

internal enum ElementAttributes : String {
    case BackgroundColor = "backgroundcolor"
    case Columns = "columns"
    case Compression = "compression"
    case CompressionLevel = "compressionlevel"
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
    case TintColor = "tintcolor"
    case Trans = "trans"
    case Version = "version"
    case Visible = "visible"
    case Width = "width"
    case X = "x"
    case Y = "y"
}

extension PEMTmxMap {
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
        case MapElements.Map.rawValue:
            parseAttributes(attributeDict)
            currentMapElement = .Map
        case MapElements.TileSet.rawValue :
            if let value = attributeDict[ElementAttributes.Source.rawValue] {
                #if DEBUG
                print("PEMTmxMap: external tilesets are unsupported: \(value)")
                #endif
                parser.abortParsing()
                return
            }
            
            let tileSet = PEMTmxTileSet(attributes: attributeDict)
            tileSets.append(tileSet)
            currentMapElement = .TileSet
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
            let layer = PEMTmxTileLayer(attributes: attributeDict)
            tileLayers.append(layer)
            currentMapElement = .Layer
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
