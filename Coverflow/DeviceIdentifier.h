//
//  DeviceIdentifier.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 12/12/15.

#import <Foundation/Foundation.h>
#import <sys/utsname.h>

@interface DeviceIdentifier : NSObject
+ (NSString *)deviceModelName;
@property (readwrite, nonatomic, strong) NSString *DeviceIdentifier;
@end
