//
//  ImageLoader.m
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 16/04/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SDWebImageManager.h>
#import "UIImageView+WebCache.h"
#import "CDemoCollectionViewCell.h"
#import "ImageLoader.h"

@interface ImageLoader() <SDWebImageManagerDelegate>
@property (weak, nonatomic) CDemoCollectionViewCell *theCell;
@end

@implementation ImageLoader

+ (void)loadImage:(NSString *)thumb :(UIImageView *)fanart
{
    BOOL gotimage;
    @try {
        gotimage = false;
        NSURL *theURL = [NSURL URLWithString:thumb];
        
        // Check if thumbnail is cached
        if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb]) {
            [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb];
            gotimage = true;
        } else {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:thumb])
            {
                // Set cached thumbnail image on imageview
                [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumb];
                gotimage = true;
            }
        }
        
        if (!gotimage) {
            // UIImage *loading = [UIImage animatedImageNamed:@"loading.png" duration:1.0f];
            
            UIImage *loading = [UIImage imageNamed:@"loading.png"];
            
            [fanart sd_setImageWithURL:theURL placeholderImage:loading completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
             {
                 UIImage *transformedImage = [self imageManager:(SDWebImageManager *)image transformDownloadedImage:image withURL:imageURL];
                 [[SDImageCache sharedImageCache] storeImage:transformedImage forKey:thumb toDisk:YES];
             }
             ];
        }
    }
    
    @catch (NSException *exception) {
        // deal with the exception
        fanart.backgroundColor = [UIColor clearColor];
    }
}

+ (void)preloadImage:(NSString *)thumb :(CDemoCollectionViewCell*)theCell
{
    BOOL gotimage;
    @try {
        gotimage = false;
        NSURL *theURL = [NSURL URLWithString:thumb];
        
        // Check if thumbnail is cached
        if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb]) {
            [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb];
            gotimage = true;
        } else {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:thumb])
            {
                // Set cached thumbnail image on imageview
                [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumb];
                gotimage = true;
            }
        }
        
        if (!gotimage) {
            // UIImage *loading = [UIImage animatedImageNamed:@"loading.png" duration:1.0f];
            
            UIImage *loading = [UIImage imageNamed:@"loading.png"];
            
            [theCell.imageViewCoverflow sd_setImageWithURL:theURL placeholderImage:loading completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
             {
                 UIImage *transformedImage = [self imageManager:(SDWebImageManager *)image transformDownloadedImage:image withURL:imageURL];
                 [[SDImageCache sharedImageCache] storeImage:transformedImage forKey:thumb toDisk:YES];
             }
             ];
        }
    }
    
    @catch (NSException *exception) {
        // deal with the exception
        theCell.backgroundColor = [UIColor clearColor];
    }
}

+ (void)preloadImage2:(NSString *)thumb :(UITableViewCell*)theCell
{
    BOOL gotimage;
    @try {
        gotimage = false;
        NSURL *theURL = [NSURL URLWithString:thumb];
        // Check if thumbnail is cached
        if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb]) {
            [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb];
            gotimage = true;
        } else {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:thumb])
            {
                // Set cached thumbnail image on imageview
                [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumb];
                gotimage = true;
            }
        }
        
        if (!gotimage) {
            // UIImage *loading = [UIImage animatedImageNamed:@"loading.png" duration:1.0f];
            
            UIImage *loading = [UIImage imageNamed:@"loading.png"];
            
            [theCell.imageView sd_setImageWithURL:theURL placeholderImage:loading completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
             {
                 UIImage *transformedImage = [self imageManager:(SDWebImageManager *)image transformDownloadedImage:image withURL:imageURL];
                 [[SDImageCache sharedImageCache] storeImage:transformedImage forKey:thumb toDisk:YES];
             }
             ];
        }
    }
    
    @catch (NSException *exception) {
        // deal with the exception
        theCell.backgroundColor = [UIColor clearColor];
    }
}

+ (UIImage*)preloadImage3:(NSString *)thumb :(UITableViewCell*)theCell
{
    BOOL gotimage;
    UIImage *transformedImage;
    @try {
        gotimage = false;
        NSURL *theURL = [NSURL URLWithString:thumb];
        // Check if thumbnail is cached
        if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb]) {
            transformedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:thumb];
            gotimage = true;
        } else {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:thumb])
            {
                // Set cached thumbnail image on imageview
                transformedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:thumb];
                gotimage = true;
            }
        }
        
        if (!gotimage) {
            UIImage *loading = [UIImage imageNamed:@"spoiler.png"];
            
            [theCell.imageView sd_setImageWithURL:theURL placeholderImage:loading completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
             {
                 [self imageManager2:(SDWebImageManager *)image transformDownloadedImage:image withURL:imageURL];
                 [[SDImageCache sharedImageCache] storeImage:transformedImage forKey:thumb toDisk:YES];
             }
             ];
        }
        
        theCell.imageView.image = transformedImage;
    }
    
    @catch (NSException *exception) {
        // deal with the exception
        theCell.backgroundColor = [UIColor clearColor];
    }
    return transformedImage;
}

+ (UIImage *)imageManager2:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL
{
    CGSize resizedImageSize = CGSizeMake(300, 169);;
    UIGraphicsBeginImageContextWithOptions(resizedImageSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, resizedImageSize.width, resizedImageSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = resizedImage;
    return image;
}

+ (UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat width;
    if (screenBounds.size.width < screenBounds.size.height) {
        width = screenBounds.size.height;
    } else {
        width = screenBounds.size.width;
    }
    
    CGSize resizedImageSize;
    
    switch ((int)width) {
        case 1024:
            resizedImageSize = CGSizeMake(426, 569);
            break;
        case 568:
            resizedImageSize = CGSizeMake(200, 300);
            break;
        default:
            resizedImageSize = CGSizeMake(216, 288);
            break;
    }
    
    UIGraphicsBeginImageContextWithOptions(resizedImageSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, resizedImageSize.width, resizedImageSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    image = resizedImage;
    return image;
}

@end
