//
//  ImageLoader.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 16/04/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//
#import "CDemoCollectionViewCell.h"

@interface ImageLoader : CDemoCollectionViewCell
+ (void)loadImage:(NSString *)thumb :(UIImageView*)fanart;
+ (void)preloadImage:(NSString *)thumb :(CDemoCollectionViewCell*)theCell;
+ (void)preloadImage2:(NSString *)thumb :(UITableViewCell*)theCell;
+ (UIImage *)preloadImage3:(NSString *)thumb :(UITableViewCell*)theCell;
+ (UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL;
@end
