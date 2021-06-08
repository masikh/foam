//
//  KodiConfig.m
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 12/03/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KodiConfig.h"
#import "KodiControls.h"

@interface KodiConfig()
@property (nonatomic) BOOL kodiIsAvailable;
@end

@implementation KodiConfig : NSObject
@synthesize kodiIsAvailable;

+ (void)request:(NSString*)request
{
    NSString *escapedPath = [request stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableURLRequest *requestConnection = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:escapedPath]
                                                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                 timeoutInterval:2.0];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:requestConnection
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                @try {
                    if (data != nil) {
                        [self checkResult:[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]];
                    } else {
                        // Request to KODI failed, assume KODI is unavailable
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsUnAvailable" object:nil];
                    }
                } @catch (NSException *exception) {
                    NSLog(@"%@", exception);
                    // Request to KODI failed, assume KODI is unavailable
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsUnAvailable" object:nil];
                }
            }];
    [dataTask resume];
}

+ (void)requestToKodi:(NSURL*)url :(NSString*)postDataString
{
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    [req setHTTPMethod:@"POST"];
    NSData *postData = [postDataString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",[postData length]];
    [req addValue:postLength forHTTPHeaderField:@"Content-Length"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    @try {
        NSURLSessionDataTask *task = [session dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (data != nil) {
                NSLog(@"requestToKodi data: %@", data);
            }
            if (error != nil) {
                NSLog(@"requestToKodi error: %@", error);
            }
            if (response != nil) {
                NSLog(@"requestToKodi response: %@", response);
            }
        }];
        [task resume];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

+ (void)resumeOnKodi:(NSURL*)url :(NSString*)postDataString :(NSDictionary*)resume :(NSString*)kodiHostname :(NSString*)kodiUsername :(NSString*)kodiPassword
{
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    [req setHTTPMethod:@"POST"];
    NSData *postData = [postDataString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",[postData length]];
    [req addValue:postLength forHTTPHeaderField:@"Content-Length"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (data != nil) {
                [NSThread sleepForTimeInterval:1.0f];
                [KodiControls setPositionKodi:[[resume valueForKey:@"position"] floatValue] :kodiHostname :kodiUsername :kodiPassword];
                NSLog(@"resumeOnKodi data: %@", data);
            }
            if (error != nil) {
                NSLog(@"resumeOnKodi error: %@", error);
            }
            if (response != nil) {
                NSLog(@"resumeOnKodi response: %@", response);
            }
        }];
    [task resume];
}

+ (void)isKodiAvailable:(NSString*)kodiUsername :(NSString*)kodiPassword :(NSString*)kodiHostname
{
    NSString *toKodi = [NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request={\"jsonrpc\": \"2.0\", \"method\": \"JSONRPC.Ping\", \"id\": 1}", kodiUsername, kodiPassword, kodiHostname];
    [self request:toKodi];
}

+ (void)checkResult:(NSMutableData *)responseData
{
    @try {
        //id value = [responseData objectForKey:@"result"];
        id value = [responseData valueForKey:@"result"];
        id errorMessage = [responseData valueForKeyPath:@"error.message"];
        NSString *kodiRPCResult = (NSString *)value;
        if ([(NSString *)errorMessage isEqualToString:@"Parse error."]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsUnAvailable" object:nil];
        } else if ([kodiRPCResult isEqualToString:@"OK"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsAvailable" object:nil];
        } else if ([kodiRPCResult isEqualToString:@"OK"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsAvailable" object:nil];
        } else if ([kodiRPCResult isEqualToString:@"pong"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsAvailable" object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsUnAvailable" object:nil];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"checkResult: %@", (NSString *)exception);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiIsUnAvailable" object:nil];
    }
}

@end
