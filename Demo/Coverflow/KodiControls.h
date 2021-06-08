//
//  KodiConfig.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 12/03/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

@interface KodiControls : NSObject
+ (void)KodiControlView:(UIView*)thisView :(NSString*)username :(NSString*)password :(NSString*)hostname;
+ (void)setVolumeKodi:(float)value;
+ (void)setPositionKodi:(float)value;
+ (void)setPositionKodi:(float)value :(NSString*)Hostname :(NSString*)Username :(NSString*)Password;
@end
