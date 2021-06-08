//
//  UIImageBurnColorAddition.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 03/01/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Colored)
+ (UIImage *) image:(UIImage *)image withColor:(UIColor *)color;
+ (UIImage *)imageNamed:(NSString *)name withMaskColor:(UIColor *)color;
@end
