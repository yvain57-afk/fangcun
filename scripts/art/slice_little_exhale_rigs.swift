// Extract image-model-authored layers without drawing, recoloring, warping or alpha keying.
import AppKit
import ImageIO
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sheets: [(String, [(String, [Int])])] = [
  ("cat-rig", [("cat-base", [40,83,545,571]), ("cat-left-paw",[873,303,170,184]),
    ("cat-right-paw",[241,879,180,182]), ("cat-rest-base",[628,681,551,552])]),
  ("dog-rest-rig", [("dog-rest-body",[36,296,586,302]), ("dog-rest-head",[695,220,489,301]),
    ("dog-alert-head",[70,764,484,292]), ("dog-rest-paws",[78,450,235,85])]),
  ("dog-sit-rig", [("dog-base",[188,50,539,544]), ("dog-left-paw",[1019,243,210,217]),
    ("dog-right-paw",[306,721,208,213]), ("flag",[1041,666,308,291])])
]
var manifest: [[String:Any]] = []
for (sheet,parts) in sheets {
  let source = root.appendingPathComponent("docs/content/little-exhale-2/art/\(sheet).png")
  let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(source as CFURL,nil)!,0,nil)!
  for (name,b) in parts {
    let crop = image.cropping(to: CGRect(x:b[0],y:b[1],width:b[2],height:b[3]))!
    let directory = root.appendingPathComponent("InnerBalance/InnerBalanceApp/Assets.xcassets/LE2-\(name).imageset")
    try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
    let destination = CGImageDestinationCreateWithURL(directory.appendingPathComponent("Artwork.png") as CFURL,UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(destination,crop,nil);precondition(CGImageDestinationFinalize(destination))
    let contents: [String:Any] = ["images":[["filename":"Artwork.png","idiom":"universal"]],"info":["author":"xcode","version":1]]
    try JSONSerialization.data(withJSONObject:contents,options:[.prettyPrinted,.sortedKeys]).write(to:directory.appendingPathComponent("Contents.json"))
    manifest.append(["asset":"LE2-"+name,"source":sheet+".png","crop":b,"alpha":"original preserved"])
  }
}
try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("docs/content/little-exhale-2/art/layers.json"))
print("Extracted \(manifest.count) authored layers")
