internal enum Elements : String {
    case None
    case Data = "data"
    case Group = "group"
    case Image = "image"
    case ImageLayer = "imagelayer"
    case Layer = "layer"
    case Map = "map"
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
    
    func parserDidStartDocument(_ parser: XMLParser) {
        elementPath.removeAll()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
            
        // top level elements
        case Elements.Map.rawValue:
            parseAttributes(attributeDict)
            elementPath.append(self)
        case Elements.TileSet.rawValue :
            if let value = attributeDict[ElementAttributes.Source.rawValue] {
                #if DEBUG
                print("PEMTmxMap: external tilesets are unsupported: \(value)")
                #endif
                parser.abortParsing()
                return
            }
            
            let tileSet = PEMTmxTileSet(attributes: attributeDict)
            tileSets.append(tileSet)
            elementPath.append(tileSet)
        case Elements.Layer.rawValue:
            let layer = PEMTmxTileLayer(attributes: attributeDict)
            tileLayers.append(layer)
            elementPath.append(layer)
        case Elements.ObjectGroup.rawValue:
            break
        case Elements.ImageLayer.rawValue:
            break
        case Elements.Group.rawValue:
            break
        case Elements.Properties.rawValue:
            break
        case Elements.Template.rawValue:
            break

        // child elements
        case Elements.Image.rawValue:
            if let currentElement = elementPath.last as? PEMTmxTileSet {
                currentElement.setTileAtlasImage(attributes: attributeDict)
                break
            }
            
            #if DEBUG
            print("PEMTmxMap: unexpeced <\(elementName)> for \(String(describing: elementPath.last)).")
            #endif
            parser.abortParsing()
        case Elements.Data.rawValue:
            if let value = attributeDict[ElementAttributes.Encoding.rawValue] {
                if let encoding = DataEncoding(rawValue: value) {
                    dataEncoding = encoding
                } else {
                    #if DEBUG
                    print("PEMTmxMap: unsupported data encoding: \(String(describing: value))")
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
        default:
            #if DEBUG
            print("PEMTmxMap: unsupported TMX element name: <\(elementName)>")
            #endif
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName {
            
        // top level elements
        case Elements.Map.rawValue:
            break
        case Elements.TileSet.rawValue :
            break
        case Elements.Layer.rawValue:
            break
        case Elements.ObjectGroup.rawValue:
            break
        case Elements.ImageLayer.rawValue:
            break
        case Elements.Group.rawValue:
            break
        case Elements.Properties.rawValue:
            break
        case Elements.Template.rawValue:
            break
            
        // child elements
        case Elements.Image.rawValue:
            break
        case Elements.Data.rawValue:
            guard let tileLayer = tileLayers.last else {
                #if DEBUG
                print("PEMTmxMap: unexpected <\(elementName)> for \(String(describing: elementPath.last)).")
                #endif
                parser.abortParsing()
                return
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
                print("PEMTmxMap: could not decode layer data for layer: \(String(describing: tileLayer.layerName))")
                #endif
                parser.abortParsing()
            }
        default:
            #if DEBUG
            print("PEMTmxMap: unsupported TMX element name: <\(elementName)>")
            #endif
        }
        
        currentParseString.removeAll()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentParseString += string
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        #if DEBUG
        print("PEMTmxMap: parseErrorOccurred: \(parseError)")
        #endif
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        elementPath.removeAll()
    }
    
    // MARK: - Decoding data

    fileprivate func decodeData(csv data: String) -> [UInt32] {
        return cleanString(data).components(separatedBy: ",").map {UInt32($0)!}
    }
    
    func cleanString(_ string: String) -> String {
        var result = string.replacingOccurrences(of: "\n", with: "")
        result = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return result.replacingOccurrences(of: " ", with: "")
    }
    
    fileprivate func decodeData(base64 data: String, compression: DataCompression = .None) -> [UInt32]? {
        guard let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) else {
            #if DEBUG
            print("PEMTmxMap: data is not base64 encoded.")
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
                print("PEMTmxMap: zstd compression is not supported.")
                #endif
                return nil
            default:
                return decodedData.toArray(type: UInt32.self)
        }
        
        return nil
    }
}
