//
//  VideoPlayerViewController.h
//  FOAM
//
//  Created by Sławomir Bienia on 12/02/2019.
//  Copyright © 2019 toxicsoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileVLCKit/MobileVLCKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) NSURL *videoUrl;
@property (nonatomic) bool kodiIsAvailable;
@property (nonatomic)VLCMediaPlayer *mediaPlayer;

- (void)killVideoPlayer;
@end


NS_ASSUME_NONNULL_END
