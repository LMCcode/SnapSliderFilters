//
//  SNFilter.swift
//  Pods
//
//  Created by Paul Jeannot on 04/05/2016.
//
//

import UIKit

public class SNFilter: UIImageView {
    
    // Full list of filters available here : https://developer.apple.com/library/tvos/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
    public static let filterNameList = ["No Filter" , "CIPhotoEffectFade", "CIPhotoEffectChrome", "CIPhotoEffectTransfer", "CIPhotoEffectInstant", "CIPhotoEffectMono", "CIPhotoEffectNoir", "CIPhotoEffectProcess", "CIPhotoEffectTonal"]
    public var name:String?
    var stickers = [SNSticker]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(frame: CGRect, withImage image:UIImage, withContentMode mode:UIViewContentMode = .ScaleAspectFill) {
        super.init(frame: frame)
        self.contentMode = mode
        self.clipsToBounds = true
        self.image = image
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func mask(maskRect: CGRect) {
        let maskLayer = CAShapeLayer()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, maskRect)
        maskLayer.path = path
        self.layer.mask = maskLayer;
    }
    
    func updateMask(maskRect: CGRect, newXPosition: CGFloat) {
        let maskLayer = CAShapeLayer()
        let path = CGPathCreateMutable()
        var rect = maskRect
        rect.origin.x = newXPosition
        CGPathAddRect(path, nil, rect)
        maskLayer.path = path
        self.layer.mask = maskLayer;
    }
    
    func applyFilter(filterNamed name:String) -> SNFilter {
        
        let filter:SNFilter = self.copy() as! SNFilter
        filter.name = name
        
        if (SNFilter.filterNameList.contains(name) == false) {
            print("Filter not existing")
            return filter
        }
        else if name == "No Filter" {
            return filter
        }
        else
        {
            // Create and apply filter
            // 1 - create source image
            let sourceImage = CIImage(image: filter.image!)
            
            // 2 - create filter using name
            let myFilter = CIFilter(name: name)
            myFilter?.setDefaults()
            
            // 3 - set source image
            myFilter?.setValue(sourceImage, forKey: kCIInputImageKey)
            
            // 4 - create core image context
            let context = CIContext(options: nil)
            
            // 5 - output filtered image as cgImage with dimension.
            let outputCGImage = context.createCGImage(myFilter!.outputImage!, fromRect: myFilter!.outputImage!.extent)
            
            // 6 - convert filtered CGImage to UIImage
            let filteredImage = UIImage(CGImage: outputCGImage)
            
            // 7 - set filtered image to array
            filter.image = filteredImage
            return filter
        }
    }
    
    public func addSticker(sticker: SNSticker) {
        self.stickers.append(sticker)
    }
    
    public static func generateFilters(originalImage: SNFilter, filters:[String]) -> [SNFilter] {
        
        var finalFilters = [SNFilter]()
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        let qos_attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0)
        let syncQueue = dispatch_queue_create("com.snapsliderfilters.app", qos_attr)
        
        // Each filter can be generated on a different thread
        dispatch_apply(filters.count, queue) { iteration in
            let filterComputed = originalImage.applyFilter(filterNamed: filters[iteration])
            dispatch_sync(syncQueue) {
                finalFilters.append(filterComputed)
                return
            }
        }
        
        return finalFilters
    }
}

// MARK: - NSCopying protocol

extension SNFilter: NSCopying {
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = SNFilter(frame: self.frame)
        copy.backgroundColor = self.backgroundColor
        copy.image = self.image
        copy.name = name
        copy.contentMode = self.contentMode
        
        for s in stickers {
            copy.stickers.append(s.copy() as! SNSticker)
        }
        return copy
    }
}