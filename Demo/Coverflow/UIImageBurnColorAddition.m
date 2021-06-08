//
//  UIImageBurnColorAddition.m
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 03/01/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImageBurnColorAddition.h"


@implementation UIImage (Colored)

+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color
{
    // load the image
    UIImage *img = image;

    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(img.size);

    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();

    // set the fill color
    [color setFill];

    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);

    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);

    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //return the color-burned image
    return coloredImg;
}


-(UIImage *) negativeImage
{
    UIGraphicsBeginImageContext(self.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, self.size.width, self.size.height));
    UIImage *negativeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return negativeImage;
}

- (UIImage *) imageWithWhiteBackground
{
    UIImage *negative = [self negativeImage];
    
    UIGraphicsBeginImageContext(negative.size);
    CGContextSetRGBFillColor (UIGraphicsGetCurrentContext(), 1, 1, 1, 1);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = CGPointZero;
    thumbnailRect.size.width = negative.size.width;
    thumbnailRect.size.height = negative.size.height;
    
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, negative.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    CGContextFillRect(UIGraphicsGetCurrentContext(), thumbnailRect);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), thumbnailRect, negative.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)imageNamed:(NSString *)name withMaskColor:(UIColor *)color
{
    // load the image
    UIImage *image = [UIImage imageNamed:name];
    UIImage *formattedImage = [image imageWithWhiteBackground];
        
    CGRect rect = {{0, 0}, {formattedImage.size.width, formattedImage.size.height}};
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *tempColor = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef maskRef = [formattedImage CGImage];
    CGImageRef maskcg = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                          CGImageGetHeight(maskRef),
                                          CGImageGetBitsPerComponent(maskRef),
                                          CGImageGetBitsPerPixel(maskRef),
                                          CGImageGetBytesPerRow(maskRef),
                                          CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef maskedcg = CGImageCreateWithMask([tempColor CGImage], maskcg);
    CGImageRelease(maskcg);
    UIImage *result = [UIImage imageWithCGImage:maskedcg];
    CGImageRelease(maskedcg);
    UIImage *final = [UIImage image:result withColor:color];
    return final;
}

@end
