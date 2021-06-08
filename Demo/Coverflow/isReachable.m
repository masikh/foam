//
//  getIPAddress.m
//  FOAM
//
//  Created by Robert Nagtegaal on 20/12/2019.

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>

#import "isReachable.h"

@interface isReachable()
@end

@implementation isReachable : NSObject

+ (NSString *)set_host :(NSString *)hostname_internal :(NSString *)hostname_external {
    @try {
        const char *target = [hostname_internal UTF8String];
        struct hostent *hostentry;
        hostentry = gethostbyname(target);
        struct in_addr **addr_list;
           addr_list = (struct in_addr **)hostentry->h_addr_list;
        char* ipAddr = inet_ntoa(*addr_list[0]);
        NSString *ipaddress = [NSString stringWithFormat:@"%s", ipAddr];
        
        NSString *address = @"error";
        struct ifaddrs *interfaces = NULL;
        struct ifaddrs *temp_addr = NULL;
        int success = 0;
        // retrieve the current interfaces - returns 0 on success
        success = getifaddrs(&interfaces);
        if (success == 0) {
            // Loop through linked list of interfaces
            temp_addr = interfaces;
            while(temp_addr != NULL) {
                if(temp_addr->ifa_addr->sa_family == AF_INET) {
                    // Check if interface is en0 which is the wifi connection on the iPhone
                    if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                        // Get NSString from C String
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
        }
        // Free memory
        freeifaddrs(interfaces);
        
        NSArray *items = [address componentsSeparatedByString:@"."];   //take the one array for split the string
        NSString *network = [NSString stringWithFormat:@"%@.%@.%@", [items objectAtIndex:0], [items objectAtIndex:1], [items objectAtIndex:2]];
        
        if ([ipaddress containsString:network]) {
            return hostname_internal;
        }
        return hostname_external;
    }
    @catch (NSException *exception) {
        return hostname_internal;
    }
} 

@end
