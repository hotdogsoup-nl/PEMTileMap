// XML Elements
let XMLElementMap = "map"
let XMLElementTileSet = "tileset"
let XMLElementLayer = "layer"
let XMLElementObjectGroup = "objectgroup"
let XMLElementImageLayer = "imagelayer"
let XMLElementGroup = "group"
let XMLElementProperties = "properties"
let XMLElementTemplate = "template"

// XML Attributes
let XMLAttributeBackgroundColor = "backgroundcolor"
let XMLAttributeColumns = "columns"
//let XMLAttributeCompressionLevel = "compressionlevel"
let XMLAttributeFirstGid = "firstgid"
let XMLAttributeHeight = "height"
let XMLAttributeHexSideLength = "hexsidelength"
let XMLAttributeInfinite = "infinite"
let XMLAttributeMargin = "margin"
let XMLAttributeName = "name"
//let XMLAttributeNextLayerId = "nextlayerid"
//let XMLAttributeNextObjectId = "nextobjectid"
let XMLAttributeObjectAlignment = "objectalignment"
let XMLAttributeOrientation = "orientation"
let XMLAttributeParallaxOriginX = "parallaxoriginx"
let XMLAttributeParallaxOriginY = "parallaxoriginy"
let XMLAttributeRenderOrder = "renderorder"
let XMLAttributeRows = "rows"
let XMLAttributeSource = "source"
let XMLAttributeSpacing = "spacing"
let XMLAttributeStaggerAxis = "staggeraxis"
let XMLAttributeStaggerIndex = "staggerindex"
let XMLAttributeTileCount = "tilecount"
let XMLAttributeTiledVersion = "tiledversion"
let XMLAttributeTileHeight = "tileheight"
let XMLAttributeTileWidth = "tilewidth"
let XMLAttributeVersion = "version"
let XMLAttributeWidth = "width"

extension PEMTMXMap {    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
        case XMLElementMap:
            getAttributes(attributeDict)
        case XMLElementTileSet :
            if let value = attributeDict[XMLAttributeSource] {
                #if DEBUG
                print("PEMTMXMap: external tilesets unsupported: \(value)")
                #endif
                parser.abortParsing()
                return
            }
            
            var gId = UInt(0)
            if let value = attributeDict[XMLAttributeFirstGid] {
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
        xmlCharacters += string
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        #if DEBUG
        print("PEMTMXMap: parseErrorOccurred: \(parseError)")
        #endif
    }
}
