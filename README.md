<p align="center">
<a href="https://github.com/p-edge-media/PEMTmxMap"><img src="Demo/Assets.xcassets/logo.imageset/logo.png" height="100"/>
<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5-brightgreen.svg"></a>
<a href="https://developer.apple.com/download/more/"><img src="https://img.shields.io/badge/Xcode-orange.svg"></a>
<a href="https://www.apple.com"><img src="https://img.shields.io/badge/platforms-iOS%20%7C%20tvOS%20%7C%20macOS-red.svg"></a>
</p>

**PEMTmxMap** creates `SpriteKit` game maps from TMX Map files. [TMX Map files][tmx-map-url] can be created and edited with [Tiled][tiled-url].

Based on the well-known [JSTileMap][jstilemap-url] project which was famously used in Ray Wenderlichs SpriteKit [SuperKoalio][superkoalio-url] tutorial but no longer seems to be maintained. I hope to make a light-weight framework that supports iOS, macOS and tvOS.

I also made a [modern Swift version of the SuperKoalio game][superkoalio-project-url], which uses `PEMTmxMap` to generate the map and also supports iOS, macOS and tvOS.

## TMX Features

- [X] read and parse TMX map files
- [X] CSV, Base64 layer formats with gzip, zlib or no compression
- [ ] Zstandard compression 
- [X] fixed size maps
- [ ] infinite maps
- [X] orthogonal map types
- [ ] isometric map types
- [ ] isometric staggerd map types
- [ ] hexagonal staggered map types
- [X] map background color
- [X] embedded tile sets
- [X] tilesets based on a tileset image
- [X] tilesets based on a collection of images
- [X] external TSX tile sets
- [ ] terraintypes and wangsets
- [ ] object groups
- [ ] object template files
- [ ] image layers
- [ ] grouped layers
- [X] layer tinting
- [X] flipped tiles
- [ ] animated tiles
- [ ] properties

## PEMTmxMap Features

- [X] Swift 5
- [ ] Objective-C compatibility
- [X] iOS (>13.6), macOS (>10.15), tvOS (>13.4)
- [ ] watchOS support
- [X] generates the TMX map as an `SKNode` with child elements as `SKNode` subclasses (eg. a tile as a `SKSpriteNode` etc.)
- [ ] supports both nearest neighbor and linear texture antialiasing
- [ ] access layers, tiles, objects
- [ ] camera tilt and zoom
- [ ] anti-tearing (removing tear lines between tiles)
- [ ] scroll using the TMX parallax properties
- [ ] Touch, Mouse, Keyboard control

[tmx-map-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#
[tiled-url]:http://www.mapeditor.org
[jstilemap-url]:https://github.com/slycrel/JSTileMap
[superkoalio-project-url]:https://github.com/p-edge-media/PEMSuperKoalio
[superkoalio-url]:https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1
