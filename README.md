<p align="center">
<a href="https://github.com/p-edge-media/PEMTileMap"><img src="Doc/logo.png" height="100"/>
<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5-brightgreen.svg"></a>
<a href="https://developer.apple.com/download/more/"><img src="https://img.shields.io/badge/Xcode-orange.svg"></a>
<a href="https://www.apple.com"><img src="https://img.shields.io/badge/platforms-iOS%20%7C%20tvOS%20%7C%20macOS-red.svg"></a>
</p>
  
**PEMTileMap** creates `SpriteKit` game maps from TMX Map files. [TMX Map files][tmx-map-url] can be created and edited with [Tiled][tiled-url].

Based on the well-known [JSTileMap][jstilemap-url] project which was famously used in Ray Wenderlichs SpriteKit [SuperKoalio][superkoalio-url] tutorial but no longer seems to be maintained. I hope to make a light-weight framework that supports iOS, macOS and tvOS.
  
<p align="center">
<img src="Doc/screenshot_macos_01.png" height="450"/>
</p>

I also made a [Swift version of the SuperKoalio game][superkoalio-project-url], which uses `PEMTileMap` to generate the map and also supports iOS, macOS and tvOS.
  
## TMX Features
- [X] read and parse TMX map files
- [X] CSV, Base64 layer formats with gzip, zlib or no compression
- [X] fixed size maps
- [X] orthogonal map types
- [X] map background color
- [X] embedded tile sets
- [X] tilesets based on a tileset image
- [X] tilesets based on a collection of images
- [X] tilesets using a specific color for transparency
- [X] external TSX tile sets
- [X] object groups
- [X] object template files
- [X] image layers
- [X] layer groups
- [X] layer tinting
- [X] flipped tiles
- [X] animated tiles
- [X] properties
  
## Not (yet) supported
- [ ] Zstandard compression 
- [ ] world files
- [ ] infinite maps
- [ ] isometric map types
- [ ] isometric staggered map types
- [ ] hexagonal staggered map types
- [ ] terraintypes, wangsets, transformations
- [ ] image `<trans>` color

## PEMTileMap Features
- [X] Swift code
- [ ] Objective-C compatibility
- [X] iOS (>13.6), macOS (>10.15), tvOS (>13.4)
- [X] generate TMX maps as `SKNode` objects with child elements as `SKNode` subclasses (eg. a tile as a `SKSpriteNode`, a polygon object as an `SKShapeNode`, etc.)
- [X] both nearest neighbor and linear texture antialiasing
- [X] camera tilt and zoom
- [ ] access layers, tiles, objects
- [ ] parallax scroll
- [ ] anti-tearing (removing tear lines between tiles)
  
## Known issues
Please refer to the [issue tracker][issues-url] on GitHub. All bugs reports, feature requests and comments are welcome.

## Installation
### Swift package

In Xcode project settings, under "Package Dependencies" add the PEMTileMap repository.

    URL: https://github.com/hotdogsoup-nl/PEMTileMap.git
    Dependency rule: branch
    Branch: master
  
### Cocoapods & Carthage
These dependency managers are not supported and will not be supported in the future.
  
## Usage
#### Loading the map
The tilemap should be loaded in your `SKScene` referring the map file name and the associated `SKView`.

```swift
  if let newMap = PEMTileMap(mapName: "superkoalio.tmx", view: skView!) {
    // center the map on the screen
    newMap.position = CGPoint(x: newMap.mapSizeInPoints().width * -0.5, y: newMap.mapSizeInPoints().height * -0.5)
    addChild(newMap)
  }
```
  
The map will now render and appear on the scene as an `SKNode`. It will contain child nodes for all TMX Map layers and groups which contain the tiles and other objects as children.
  
#### Accessing map functions
`PEMTileMap` has several public properties and functions that can be use to access map properties such as its orientation, highest used zPosition, map size (in tiles or in points) and for converting scene coordinates to map coordinates and vice versa.
  
#### Accessing layers, tiles, objects
`PEMTileMap` has several functions to access layers, tiles, and objects on the map.
  
#### Using a camera
You are responsible for creating and controlling the camera in your scene. `PEMTileMap` does however feature a basic `moveCamera` function to move the camera around the map. Set the `cameraNode` property to point to your camera before calling `moveCamera`.
  
#### Use the background color
To set the background color of your `SKScene` to match the map background color:
  
```swift
    if newMap.backgroundColor != nil {
        backgroundColor = newMap.backgroundColor!
    }
```
  
## Build the Demo app
Download the repository and open the PEMTileMap Xcode project. Build any of the iOS, macOS or tvOS targets. Depending on the platform choice, you may get a build error stating that a provisioning profile is required. In "Signing and Capabilities", make sure each target has either automatic signing enabled or select the correct provisioning profile.
  
If a build error occurs stating `Resource fork, Finder information, or similar detritus not allowed` there is an issue with image files in the project. Run `sudo xattr -cr *` on all image file folders in the project and clean the build folder to fix.

## License
Licensed under the [MIT license](license.md).

[issues-url]:https://github.com/hotdogsoup-nl/PEMTileMap/issues
[tmx-map-url]:https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#
[tiled-url]:http://www.mapeditor.org
[jstilemap-url]:https://github.com/slycrel/JSTileMap
[superkoalio-project-url]:https://github.com/hotdogsoup-nl/PEMSuperKoalio
[superkoalio-url]:https://www.raywenderlich.com/2554-sprite-kit-tutorial-how-to-make-a-platform-game-like-super-mario-brothers-part-1
