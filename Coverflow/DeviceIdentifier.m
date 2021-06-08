//
//  DeviceIdentifier.m
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 12/12/15.

#import "DeviceIdentifier.h"

@interface DeviceIdentifier ()
@end

#pragma mark -

@implementation DeviceIdentifier : NSObject

@synthesize DeviceIdentifier = _DeviceIdentifier;


+ (NSString*)deviceModelName {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    //MARK: More official list is at
    //http://theiphonewiki.com/wiki/Models
    //MARK: You may just return machineName. Following is for convenience
    
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iPhone Simulator",
      @"x86_64":   @"class_0",
      
      @"iPhone1,1":    @"class_3",
      @"iPhone1,2":    @"class_3",
      @"iPhone2,1":    @"class_3",
      @"iPhone3,1":    @"class_2",
      @"iPhone3,2":    @"class_2",
      @"iPhone3,3":    @"class_2",
      @"iPhone4,1":    @"class_2",
      @"iPhone5,1":    @"class_1",
      @"iPhone5,2":    @"class_1",
      @"iPhone5,3":    @"class_1",
      @"iPhone5,4":    @"class_1",
      @"iPhone6,1":    @"class_1",
      @"iPhone6,2":    @"class_1",
      
      @"iPhone7,1":    @"class_1",
      @"iPhone7,2":    @"class_1",
      
      @"iPhone8,1":    @"class_1",
      @"iPhone8,2":    @"class_1",
      
      @"iPad2,1":  @"class_0",
      @"iPad2,2":  @"class_0",
      @"iPad2,3":  @"class_0",
      @"iPad2,4":  @"class_0",
      @"iPad2,5":  @"class_0",
      @"iPad2,6":  @"class_0",
      @"iPad2,7":  @"class_0",
      @"iPad3,1":  @"class_0",
      @"iPad3,2":  @"class_0",
      @"iPad3,3":  @"class_0",
      @"iPad3,4":  @"class_0",
      @"iPad3,5":  @"class_0",
      @"iPad3,6":  @"class_0",
      
      @"iPad4,1":  @"class_0",
      @"iPad4,2":  @"class_0",
      @"iPad4,3":  @"class_0",
      
      @"iPad5,3":  @"class_0)",
      @"iPad5,4":  @"class_0",
      
      @"iPad4,4":  @"class_0",
      @"iPad4,5":  @"class_0",
      @"iPad4,6":  @"class_0",
      
      @"iPad4,7":  @"class_0",
      @"iPad4,8":  @"class_0",
      @"iPad4,9":  @"class_0",
      
      @"iPod4,1":  @"class_0",
      @"iPod5,1":  @"class_1",
      @"iPod7,1":  @"class_2",
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
        
    }
    
    return deviceName;
}

@end
