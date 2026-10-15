// Production atlas extraction only: no redraw, recoloring or white-removal.
import AppKit
import ImageIO
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sheets: [(String, [(String, [Int])])] = [
("torso", [("cat",[75,85,510,535]),("dog",[655,85,500,535]),("cat-side",[90,660,500,485]),("dog-side",[570,700,640,455])]),
("cat", [("poster",[35,30,360,380]),("head",[425,110,315,285]),("closed",[795,110,330,285]),("body",[1170,120,350,280]),("paw-left",[170,480,150,220]),("paw-right",[465,480,150,220]),("tail",[815,465,200,230]),("exhale",[1150,435,375,290]),("flower",[90,770,205,230]),("leaf",[405,800,200,190]),("mat",[660,770,430,230]),("crouch",[1130,720,400,290])]),
("dog", [("poster",[35,25,380,380]),("head",[420,110,330,270]),("closed",[805,110,325,270]),("body",[1175,130,330,270]),("ear-left",[40,445,300,245]),("ear-right",[460,445,260,245]),("paw-left",[870,445,170,245]),("paw-right",[1205,445,170,245]),("tail",[155,765,190,200]),("flag",[455,725,280,280]),("leaf",[795,785,245,190]),("crouch",[1105,740,410,260])]),
("rest", [("poster",[40,120,445,250]),("body",[490,145,340,225]),("closed",[855,145,275,235]),("head",[1210,145,280,235]),("paw",[70,445,300,190]),("legs",[445,455,270,185]),("ear-left",[850,425,220,210]),("ear-right",[1220,425,210,210]),("blanket",[20,720,375,225]),("pillow",[405,780,340,170]),("prone",[750,720,370,225]),("crouch",[1130,670,395,300])])]
var manifest: [[String: Any]] = []
for (sheet, parts) in sheets {
 let sourceURL = root.appendingPathComponent("docs/plans/fangcun-breathing-v4/art/\(sheet)-atlas-source.png")
 let src = CGImageSourceCreateWithURL(sourceURL as CFURL,nil)!
 let full = CGImageSourceCreateImageAtIndex(src,0,nil)!
 for (part,bounds) in parts {
  let rect = CGRect(x:bounds[0],y:bounds[1],width:bounds[2],height:bounds[3])
  let crop = full.cropping(to: rect)!
  let name = "PracticeV4-\(sheet)-\(part)"
  let directory=root.appendingPathComponent("InnerBalance/InnerBalanceApp/Assets.xcassets/\(name).imageset")
  try FileManager.default.createDirectory(at: directory,withIntermediateDirectories:true)
  let dest=CGImageDestinationCreateWithURL(directory.appendingPathComponent("Artwork.png") as CFURL,UTType.png.identifier as CFString,1,nil)!
  CGImageDestinationAddImage(dest,crop,nil); precondition(CGImageDestinationFinalize(dest))
  let contents: [String:Any] = ["images":[["filename":"Artwork.png","idiom":"universal"]],"info":["author":"xcode","version":1]]
  try JSONSerialization.data(withJSONObject:contents,options:[.prettyPrinted,.sortedKeys]).write(to:directory.appendingPathComponent("Contents.json"))
  manifest.append(["asset":name,"source":"art/\(sheet)-atlas-source.png","crop":bounds,"alpha":"original RGBA preserved; cream not keyed out"])
 }
}
try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("docs/plans/fangcun-breathing-v4/art/layers.json"))
print("Extracted \(manifest.count) original-art layers")
