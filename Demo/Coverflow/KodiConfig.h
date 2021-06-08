//
//  KodiConfig.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 12/03/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

@interface KodiConfig : NSObject
+ (void)isKodiAvailable:(NSString*)kodiUsername :(NSString*)kodiPassword :(NSString*)kodiHostname;
+ (void)request:(NSString*)request;
+ (void)requestToKodi:(NSURL*)kodiPlayer :(NSString*)postData;
+ (void)resumeOnKodi:(NSURL*)kodiPlayer :(NSString*)postData :(NSDictionary*)position :(NSString*)kodiHostname :(NSString*)kodiUsername :(NSString*)kodiPassword;
@end
