internal enum MapElements : String {
    case Data = "data"
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

internal enum MapElementAttributes : String {
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
            if let value = attributeDict[MapElementAttributes.Source.rawValue] {
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
                guard let tileSet = tileSets.last else {
                    #if DEBUG
                    print("PEMTmxMap: found <\(elementName)> for non-existing <\(currentMapElement)>.")
                    #endif
                    parser.abortParsing()
                    return
                }
                tileSet.setTileSetImage(attributes: attributeDict)
            default:
                #if DEBUG
                print("PEMTmxMap: unexpected XML element name: <\(elementName)> as child of <\(currentMapElement.rawValue)>")
                #endif
            }
        case MapElements.Layer.rawValue:
            let layer = PEMTmxTileLayer(attributes: attributeDict)
            tileLayers.append(layer)
            currentMapElement = .Layer
        case MapElements.Data.rawValue:
            if let value = attributeDict[MapElementAttributes.Encoding.rawValue] {
                if let encoding = DataEncoding(rawValue: value) {
                    dataEncoding = encoding
                } else {
                    #if DEBUG
                    print("PEMTmxMap: unsupported data encoding: \(String(describing: value))")
                    #endif
                    parser.abortParsing()
                }
            }
            
            if let value = attributeDict[MapElementAttributes.Compression.rawValue] {
                if let compression = DataCompression(rawValue: value) {
                    dataCompression = compression
                } else {
                    dataCompression = .None
                }
            }

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
        case MapElements.Data.rawValue:
            guard let tileLayer = tileLayers.last else {
                #if DEBUG
                print("PEMTmxMap: found <\(elementName)> for non-existing <\(currentMapElement)>.")
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
