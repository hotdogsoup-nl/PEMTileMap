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
let XMLAttributeVersion = "version"
let XMLAttributeTiledVersion = "tiledversion"
let XMLAttributeOrientation = "orientation"
let XMLAttributeRenderOrder = "renderorder"
//let XMLAttributeCompressionLevel = "compressionlevel"
let XMLAttributeWidth = "width"
let XMLAttributeHeight = "height"
let XMLAttributeTileWidth = "tilewidth"
let XMLAttributeTileHeight = "tileheight"
let XMLAttributeHexSideLength = "hexsidelength"
let XMLAttributeStaggerAxis = "staggeraxis"
let XMLAttributeStaggerIndex = "staggerindex"
let XMLAttributeParallaxOriginX = "parallaxoriginx"
let XMLAttributeParallaxOriginY = "parallaxoriginy"
let XMLAttributeBackgroundColor = "backgroundcolor"
//let XMLAttributeNextLayerId = "nextlayerid"
//let XMLAttributeNextObjectId = "nextobjectid"
let XMLAttributeInfinite = "infinite"

extension PEMTMXMap {    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
        case XMLElementMap:
            getAttributes(attributeDict)
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
