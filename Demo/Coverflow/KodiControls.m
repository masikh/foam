//  KodiConfig.m
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 12/03/16.

#import <Foundation/Foundation.h>
#import <AutoScrollLabel/CBAutoScrollLabel.h>
#import "KodiControls.h"

@interface KodiControls()
@end

NSMutableData *KODIResponseData;
UIView *kodiControlView;
UIView *blockingView;
UISlider *volumeSlider;
UISlider *positionSlider;
CBAutoScrollLabel *nowPlayingTitle;
UILabel *volumePercentageLabel;
NSUInteger contentLengthInSeconds;
NSString *nowPlayingFile;
NSString *totalTimeHumanReadable;
UILabel *contentTimeLabel;
NSTimer *timer;
NSString *kodiUsername;
NSString *kodiPassword;
NSString *kodiHostname;
NSNumber *playerId;

@implementation KodiControls : NSObject


/*
 GENERIC:
 
 curl -s --data-binary '{"JSON":"DATA"}' -H 'content-type: application/json;' http://kodi:kodi@172.16.100.35:8080/jsonrpc
 
 GET/SET Position:
 
 {"jsonrpc":"2.0","method":"Player.Seek","params":{"playerid":1,"value":5},"id":1} :-> Jump to in Content 5%
 {"jsonrpc":"2.0","method":"Player.GetProperties","params":{"playerid":1,"properties":["percentage"]},"id":"1"} -> Get position in track
 {"jsonrpc":"2.0","method":"Player.GetProperties","params":{"playerid":1,"properties":["time","totaltime","percentage"]},"id":"1"} ->
 
 SET PLAY-PAUSE:
 
 {"jsonrpc": "2.0", "method": "Player.PlayPause", "params": { "playerid": 0 }, "id": 1} :-> Play/Pause
 
 STOP PLAYBACK:
 
 {"jsonrpc":"2.0", "method":"Player.Stop","params":{"playerid":1},"id":1} :-> Stop
 
 GET/SET Volume:
 
 {"jsonrpc":"2.0","method":"Application.SetVolume","params":{"volume":70},"id":1} :-> Volume to 70%
 {"jsonrpc": "2.0", "method": "Application.GetProperties", "params": {"properties": ["volume"]}, "id": 1} -> Get Volume
 
 GET CURRENT FILE PLAYING:
 {"jsonrpc": "2.0", "method": "Player.GetItem", "params": { "properties": ["file"], "playerid": 1 }, "id": "VideoGetItem"}
 
 Set Next audio track
 {"jsonrpc":"2.0","id":1,"method":"Player.SetAudioStream","params":{"playerid":1,"stream":"next"}}
 
 Set Next subtitle track
 {"jsonrpc":"2.0","id":1,"method":"Player.SetSubtitle","params":{"playerid":1,"subtitle":"next"}}
 
 */

+ (NSString*)setPositionMessage:(NSInteger)percentage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.Seek\",\"params\":{\"playerid\":%@,\"value\": %d},\"id\":1}", playerId, (int)percentage];
    return message;
}

+ (NSString*)getPositionMessage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.GetProperties\",\"params\":{\"playerid\":%@,\"properties\":[\"time\",\"totaltime\",\"percentage\",\"subtitles\"]},\"id\":\"1\"}", playerId];
    return message;
}

+ (NSString*)playPauseMessage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.PlayPause\",\"params\":{\"playerid\":%@},\"id\":1}", playerId];
    return message;
}

+ (NSString*)stopPlaybackMessage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.Stop\",\"params\":{\"playerid\":%@},\"id\":1}", playerId];
    return message;
}

+ (NSString*)setVolumeMessage:(NSInteger)percentage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Application.SetVolume\",\"params\":{\"volume\":%d},\"id\":1}", (int)percentage];
    return message;
}

+ (NSString*)getVolumeMessage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Application.GetProperties\",\"params\":{\"properties\":[\"volume\"]},\"id\": 1}"];
    return message;
}

+ (NSString*)whatIsPlayingMessage {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.GetItem\",\"params\":{\"properties\":[\"file\"],\"playerid\":%@ },\"id\":\"VideoGetItem\"}", playerId];
    return message;
}

+ (NSString*)nextAudioTrack {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.SetAudioStream\",\"params\":{\"playerid\":%@,\"stream\":\"next\"},\"id\": 1}", playerId];
    return message;
}

+ (NSString*)nextSubtitleTrack {
    NSString *message = [NSString stringWithFormat:@"{\"jsonrpc\":\"2.0\",\"method\":\"Player.SetSubtitle\",\"params\":{\"playerid\":%@,\"subtitle\":\"next\"},\"id\": 1}", playerId];
    return message;
}

+ (NSString*)getPlayerIdMessage {
    NSString *message = [NSString stringWithFormat:@"{\"id\": 1, \"jsonrpc\": \"2.0\", \"method\": \"Player.GetActivePlayers\" }"];
    return message;
}

+ (void)getKodiInfo {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    NSString *message;
    message = [self getPositionMessage];
    [self retrieveData:url :message :^(NSDictionary *dictionary) {
        float position = [[dictionary valueForKeyPath:@"result.percentage"] floatValue] / 100;
        dispatch_async(dispatch_get_main_queue(), ^{
            long currentTimeHours = [[dictionary valueForKeyPath:@"result.time.hours"] longValue];
            long currentTimeMinutes = [[dictionary valueForKeyPath:@"result.time.minutes"] longValue];;
            long currentTimeSeconds = [[dictionary valueForKeyPath:@"result.time.seconds"] longValue];;
            long totalTimeHours = [[dictionary valueForKeyPath:@"result.totaltime.hours"] longValue];;
            long totalTimeMinutes = [[dictionary valueForKeyPath:@"result.totaltime.minutes"] longValue];;
            long totalTimeSeconds = [[dictionary valueForKeyPath:@"result.totaltime.seconds"] longValue];;
            contentLengthInSeconds = (NSUInteger)(totalTimeHours * 3600) + (totalTimeMinutes * 60) + totalTimeSeconds;
            totalTimeHumanReadable = [self formattedTime:totalTimeHours :totalTimeMinutes :totalTimeSeconds];
            contentTimeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self formattedTime:currentTimeHours :currentTimeMinutes :currentTimeSeconds], totalTimeHumanReadable];
            [positionSlider setValue:position];
        });
        // NSLog(@"position: %f", position);
    }];
    message = [self getVolumeMessage];
    [self retrieveData:url :message :^(NSDictionary *dictionary) {
        float volume = [[dictionary valueForKeyPath:@"result.volume"] floatValue] / 100;
        dispatch_async(dispatch_get_main_queue(), ^{
            [volumeSlider setValue:volume];
            volumePercentageLabel.text = [NSString stringWithFormat:@"%i%%", (int)(100.0 * volumeSlider.value)];
        });
        // NSLog(@"volume: %f", volume);
    }];
    message = [self whatIsPlayingMessage];
    [self retrieveData:url :message :^(NSDictionary *dictionary) {
        NSString *title;
        @try {
            NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:[dictionary valueForKeyPath:@"result.item.label"] options:0];
            title = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        }
        @catch (NSException * e) {
            title = [dictionary valueForKeyPath:@"result.item.label"];
        }
        NSString *file = [dictionary valueForKeyPath:@"result.item.file"];
        dispatch_async(dispatch_get_main_queue(), ^{
            nowPlayingTitle.text = title;
            nowPlayingFile = file;
        });
        // NSLog(@"title: %@", title);
        // NSLog(@"file: %@", file);
    }];
}

+ (NSString*)secondsToFormattedTime:(long)timeInSeconds {
    long hours = (timeInSeconds - (timeInSeconds % 3600)) / 3600;
    timeInSeconds = timeInSeconds - (hours * 3600);
    long minutes = (timeInSeconds - (timeInSeconds % 60)) / 60;
    long seconds = timeInSeconds - (minutes * 60);
    return [self formattedTime:hours :minutes :seconds];
}

+ (NSString*)formattedTime:(long)hours :(long)minutes :(long)seconds {
    NSString *stringHours = [NSString stringWithFormat:@"%lu", hours];
    if (hours < 10) {
        stringHours = [NSString stringWithFormat:@"0%lu", hours];
    }
    NSString *stringMinutes = [NSString stringWithFormat:@"%lu", minutes];
    if (minutes < 10) {
        stringMinutes = [NSString stringWithFormat:@"0%lu", minutes];
    }
    NSString *stringSeconds = [NSString stringWithFormat:@"%lu", seconds];
    if (seconds < 10) {
        stringSeconds = [NSString stringWithFormat:@"0%lu", seconds];
    }
    return [NSString stringWithFormat:@"%@:%@:%@", stringHours, stringMinutes, stringSeconds];
}

+ (void)playPause {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    [self requestToKodi:url :[self playPauseMessage]];
}

+ (void)Stop {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    [self requestToKodi:url :[self stopPlaybackMessage]];
    [NSThread sleepForTimeInterval:1.0f];
    [self DestroyKodiControlView];
}

+ (void)setVolumeKodi:(float)value {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    NSInteger percentage = (NSInteger) roundf(value * 100);
    [self requestToKodi:url :[self setVolumeMessage:percentage]];
}

+ (void)setPositionKodi:(float)value {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    NSInteger percentage = (NSInteger) roundf(value * 100);
    [self requestToKodi:url :[self setPositionMessage:percentage]];
}

+ (void)setPositionKodi:(float)value :(NSString*)Hostname :(NSString*)Username :(NSString*)Password {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", Username, Password, Hostname]];
    NSInteger percentage = (NSInteger) roundf(value * 100);
    [self requestToKodi:url :[self setPositionMessage:percentage]];
}

+ (void)setNextAudioTrack {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    [self requestToKodi:url :[self nextAudioTrack]];
}

+ (void)setNextSubtitleTrack {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat: @"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname]];
    [self requestToKodi:url :[self nextSubtitleTrack]];
}

+ (void)retrieveData:(NSURL*) url :(NSString*)message :(void (^)(NSDictionary * dictionary))completionHandler {
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    [req setHTTPMethod:@"POST"];
    NSData *postData = [message dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",[postData length]];
    [req addValue:postLength forHTTPHeaderField:@"Content-Length"];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if (completionHandler) {
            completionHandler(dictionary);
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
    NSLog(@"%@ %@", url, postDataString);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if (data != nil) {
                                                    NSDictionary *s = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                                                    NSLog(@"requestToKodi data: %@", s);
                                                } else {
                                                    if (error != nil) {
                                                        NSLog(@"requestToKodi error: %@", error);
                                                    }
                                                    if (response != nil) {
                                                        NSLog(@"requestToKodi response: %@", response);
                                                    }
                                                }
                                            }];
    [task resume];
}

+ (void)getPlayerId
{
    NSString *message = [self getPlayerIdMessage];
    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc?request", kodiUsername, kodiPassword, kodiHostname];
    //I use NSMutableString so we could append or replace parts of the URI with query parameters in the future
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] ];
    
    // Specify that it will be a POST request
    request.HTTPMethod = @"POST";
        
    // This is how we set header fields
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
     
    // Convert your data and set your request's HTTPBody property
    NSData *requestBodyData = [message dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBodyData;
        
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        @try {
            NSMutableDictionary *tmp = [[responseData valueForKey:@"result"] objectAtIndex:0];
            playerId = [tmp valueForKey:@"playerid"];
        }
        @catch (NSException * e) {
            playerId = 0;
            NSLog(@"getPlayerId Exception: %@", e);
        }
        
    }];
    [dataTask resume];
    
}

+ (void)KodiControlView:(UIView*)thisView :(NSString*)username :(NSString*)password :(NSString*)hostname
{
    // set kodi credentials
    kodiUsername = username;
    kodiPassword = password;
    kodiHostname = hostname;
    [self getPlayerId];
    
    // Device width (the size of the canvas!)
    CGFloat deviceWidth = thisView.frame.size.width;
    CGFloat deviceHeight = thisView.frame.size.height;
    
    blockingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thisView.frame.size.width, thisView.frame.size.height)];
    blockingView.tag = 70;
    [thisView addSubview:blockingView];
    kodiControlView = [[UIView alloc] init];
    CGRect kodiControlViewRect = [self kodiControlViewSize:(float)deviceWidth :(float)deviceHeight];
    [kodiControlView setFrame:kodiControlViewRect];
    kodiControlView.layer.borderWidth = 2.0f;
    kodiControlView.layer.borderColor = [[UIColor grayColor] CGColor];;
    kodiControlView.layer.cornerRadius = 5;
    [kodiControlView.layer setMasksToBounds:YES];
    kodiControlView.tag = 70;
    
    kodiControlView.backgroundColor = [UIColor clearColor];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = kodiControlView.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.layer.cornerRadius = 5;
    blurEffectView.tag = 70;
    blurEffectView.alpha = 0.95f;
    [blurEffectView.layer setMasksToBounds:YES];
    [blockingView addSubview:kodiControlView];
    [kodiControlView addSubview:blurEffectView];
    [self BuildKodiControlView:blurEffectView :deviceWidth :deviceHeight];
    
    // Load current Volume and Position as fast as possible
    [self getKodiInfo];
}

+ (CGRect)kodiControlViewSize:(float)width :(float)height
{
    CGRect thisRect;
    switch ((int)width) {
        case 480:
        case 568:
            thisRect = CGRectMake(width / 16, 17, width * 7/8, width/5 + 68);
            break;
        case 1024:
            thisRect = CGRectMake((width / 8), 20, width * 3/4, 236);
            break;
        default:
            thisRect = CGRectMake((width / 8), 20, width * 3/4, (height / 3) + 26);
            break;
    }
    return thisRect;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (void)BuildKodiControlView:(UIView*)thisView :(CGFloat)deviceWidth :(CGFloat)deviceHeight
{
    // Set Control buttons and sliders...
    [self backButton:deviceWidth];
    [self setPlayPauseButton:deviceWidth :deviceHeight];
    [self setStopButton:deviceWidth :deviceHeight];
    [self resumeOnButton:deviceWidth :deviceHeight];
    [self setVolumeSlider:deviceWidth :deviceHeight];
    [self setPositionSlider:deviceWidth :deviceHeight];
    [self setHorizontalLine:deviceWidth :deviceHeight];
    [self setTitleLabel:deviceWidth :deviceHeight];
    [self setSubtitlesButton:deviceWidth :deviceHeight];
    [self setAudioTrackButton:deviceWidth :deviceHeight];
    [self setVolumePercentageLabel:deviceWidth :deviceHeight];
    [self setContentTimeLabel:deviceWidth :deviceHeight];
    [kodiControlView setNeedsDisplay];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(getKodiInfo) userInfo:nil repeats:YES];
}

+ (void)setStopButton:(CGFloat)width :(CGFloat)height {
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat buttonWidth;
    CGFloat buttonHeight;
    if (width == 1024) {
        offsetX = 15;
        offsetY = 80;
        buttonWidth = (width / 3) - 230;
        buttonHeight = (width / 3) - 230;
    } else {
        offsetX = 15;
        offsetY = 65;
        buttonWidth = (width / 3) - 120;
        buttonHeight = (width / 3) - 120;
    }
    UIImage *playpause = [UIImage imageNamed:@"stop_big.png"];
    UIButton *playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(offsetX, offsetY, buttonWidth, buttonHeight)];
    [playPauseButton setImage:playpause forState:UIControlStateNormal];
    [kodiControlView addSubview:playPauseButton];
    [playPauseButton addTarget:self action:@selector(Stop) forControlEvents:UIControlEventTouchUpInside];
}

+ (void)setPlayPauseButton:(CGFloat)width :(CGFloat)height {
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat buttonWidth;
    CGFloat buttonHeight;
    if (width == 1024) {
        offsetX = 25 + (width / 3) - 85;
        offsetY = 45;
        buttonWidth = (width / 3) - 160;
        buttonHeight = (width / 3) - 160;
    } else {
        offsetX = 25 + (width / 2) - 120;
        offsetY = 45;
        buttonWidth = (width / 3) - 80;
        buttonHeight = (width / 3) - 80;
    }
    UIImage *playpause = [UIImage imageNamed:@"playpause_big.png"];
    UIButton *playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(offsetX, offsetY, buttonWidth, buttonHeight)];
    [playPauseButton setImage:playpause forState:UIControlStateNormal];
    [kodiControlView addSubview:playPauseButton];
    [playPauseButton addTarget:self action:@selector(playPause) forControlEvents:UIControlEventTouchUpInside];
}

+ (void)resumeOnButton:(CGFloat)width :(CGFloat)height {
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat buttonWidth;
    CGFloat buttonHeight;
    if (width == 1024) {
        offsetX = 578;
        offsetY = 45;
        buttonWidth = (width / 3) - 160;
        buttonHeight = (width / 3) - 160;
    } else {
        offsetX = 25 + (width / 1) - 218;
        offsetY = 45;
        buttonWidth = (width / 3) - 80;
        buttonHeight = (width / 3) - 80;
    }
    UIImage *resumeOnTablet = [UIImage imageNamed:@"tablet.png"];
    UIButton *resumeOnTabletButton = [[UIButton alloc] initWithFrame:CGRectMake(offsetX, offsetY, buttonWidth, buttonHeight)];
    [resumeOnTabletButton setImage:resumeOnTablet forState:UIControlStateNormal];
    [kodiControlView addSubview:resumeOnTabletButton];
    [resumeOnTabletButton addTarget:self action:@selector(resumeOnTablet) forControlEvents:UIControlEventTouchUpInside];
}

+ (void)resumeOnTablet {
    NSLog(@"resumeOnTablet");
    
    // Get current position and url
    NSDictionary *dict = @{@"position": [NSNumber numberWithFloat:positionSlider.value], @"url": nowPlayingFile};
    NSLog(@"%@", dict);
    
    // Send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resumeOnTablet" object:nil userInfo:dict];
    
    // Send stop to kodi (destoys view)
    [self Stop];
}

+ (void)setVolumeSlider:(CGFloat)width :(CGFloat)height {
    NSLog(@"setVolumeSlider %f, %f", width, height);
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat sliderWidth;
    CGFloat sliderHeigth;
    if (width == 1024) {
        offsetX = 15;
        offsetY = 210;
        sliderWidth = (width / 3) - 30;
        sliderHeigth = 10;
    } else {
        offsetX = 15;
        offsetY = 155;
        sliderWidth = (width / 3) - 30;
        sliderHeigth = 10;
    }
    
    volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(offsetX, offsetY, sliderWidth, sliderHeigth)];
    [[UISlider appearance] setThumbImage:[self imageWithImage:[UIImage imageNamed:@"blue_slider_thumb.png"] scaledToSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    volumeSlider.minimumTrackTintColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    [volumeSlider addTarget:self action:@selector(setVolumeValueChanging:forEvent:) forControlEvents:UIControlEventTouchDragInside];
    [kodiControlView addSubview:volumeSlider];
}

+ (void)setVolumePercentageLabel:(CGFloat)width :(CGFloat)height {
    NSLog(@"setVolumePercentageLabel %f, %f", width, height);
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat labelWidth;
    CGFloat labelHeigth;
    if (width == 1024) {
        offsetX = 15;
        offsetY = 218;
        labelWidth = (width / 3) - 30;
        labelHeigth = 10;
    } else {
        offsetX = 17;
        offsetY = 168;
        labelWidth = (width / 3) - 30;
        labelHeigth = 10;
    }
    volumePercentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(offsetX, offsetY, labelWidth, labelHeigth)];
    volumePercentageLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    volumePercentageLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:8];
    volumePercentageLabel.text = [NSString stringWithFormat:@"%i%%", (int)(100.0 * volumeSlider.value)];
    [kodiControlView addSubview:volumePercentageLabel];
}

+ (void)setPositionSlider:(CGFloat)width :(CGFloat)height {
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat sliderWidth;
    CGFloat sliderHeigth;
    if (width == 1024) {
        offsetX = 15 + (width / 3) - 20;
        offsetY = 210;
        sliderWidth = (width / 3) + 73;
        sliderHeigth = 10;
    } else {
        offsetX = 15 + (width / 3) - 20;
        offsetY = 155;
        sliderWidth = (width / 2) + 10;
        sliderHeigth = 10;
    }
    positionSlider = [[UISlider alloc] initWithFrame:CGRectMake(offsetX, offsetY, sliderWidth, sliderHeigth)];
    [[UISlider appearance] setThumbImage:[self imageWithImage:[UIImage imageNamed:@"blue_slider_thumb.png"] scaledToSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    positionSlider.minimumTrackTintColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    [positionSlider setContinuous: YES];
    [positionSlider addTarget:self action:@selector(setPositionValueChanging:forEvent:) forControlEvents:UIControlEventTouchDragInside];
    [kodiControlView addSubview:positionSlider];
}

+ (void)setContentTimeLabel:(CGFloat)width :(CGFloat)height {
    CGFloat offsetX;
    CGFloat offsetY;
    CGFloat labelWidth;
    CGFloat labelHeigth;
    if (width == 1024) {
        offsetX = (width / 3) - 2;
        offsetY = 218;
        labelWidth = (width / 3) + 73;
        labelHeigth = 10;
    } else {
        offsetX = (width / 3) - 2;
        offsetY = 168;
        labelWidth = (width / 2) + 10;
        labelHeigth = 10;
    }
    contentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(offsetX, offsetY, labelWidth, labelHeigth)];
    contentTimeLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    contentTimeLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:8];
    contentTimeLabel.text = [NSMutableString stringWithString:@"00:00:00 / 00:00:00"];
    [kodiControlView addSubview:contentTimeLabel];
}

+ (void)setHorizontalLine:(CGFloat)width :(CGFloat)height {
    // Draw line below textfields
    UIView *line;
    if (width == 1024) {
        line = [[UIView alloc] initWithFrame:CGRectMake(15, 58, ((width / 16) * 12) - 30, 2)];
    } else {
        line = [[UIView alloc] initWithFrame:CGRectMake(15, 45, ((width / 16) * 14) - 30, 2)];
    }
    line.backgroundColor = [UIColor grayColor];
    line.layer.cornerRadius = 1;
    [kodiControlView addSubview:line];
}

+(void)setTitleLabel:(CGFloat)width :(CGFloat)height {
    UIColor *textColor = [UIColor colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0];
    if (width == 1024) {
        nowPlayingTitle = [[CBAutoScrollLabel alloc] initWithFrame:CGRectMake(15, 20, ((width * 3/4) - 160), 20)];
    } else {
        nowPlayingTitle = [[CBAutoScrollLabel alloc] initWithFrame:CGRectMake(15, 15, ((width * 7/8) - 160) - 30, 20)];
    }
    nowPlayingTitle.textColor = textColor;
    [kodiControlView addSubview:nowPlayingTitle];
}

+ (void)backButton:(CGFloat)width {
    UIButton *thisbutton;
    if (width == 1024) {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake((width * 3/4) - 60, 5, 50, 50)];
    } else {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake((width * 7/8) - 60, 0, 50, 50)];
    }
    [thisbutton addTarget:self action:@selector(DestroyKodiControlView) forControlEvents:UIControlEventTouchUpInside];
    UIImage *thisButtonImage = [UIImage imageNamed:@"back3.png"];
    [thisbutton setImage:thisButtonImage forState:UIControlStateNormal];
    [kodiControlView addSubview:thisbutton];
}

+ (void)setSubtitlesButton:(CGFloat)width :(CGFloat)height {
    UIButton *thisbutton;
    if (width == 1024) {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake((width * 3/4) - 100, 13, 30, 30)];
    } else {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake((width * 7/8) - 100, 13, 30, 30)];
    }
    [thisbutton addTarget:self action:@selector(setNextSubtitleTrack) forControlEvents:UIControlEventTouchUpInside];
    UIImage *thisButtonImage = [UIImage imageNamed:@"Subtitles.png"];
    [thisbutton setImage:thisButtonImage forState:UIControlStateNormal];
    [kodiControlView addSubview:thisbutton];
}

+ (void)setAudioTrackButton:(CGFloat)width :(CGFloat)height {
    UIButton *thisbutton;
    if (width == 1024) {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake((width * 3/4) - 160, 5, 50, 50)];
    } else {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake((width * 7/8) - 160, 0, 50, 50)];
    }
    [thisbutton addTarget:self action:@selector(setNextAudioTrack) forControlEvents:UIControlEventTouchUpInside];
    UIImage *thisButtonImage = [UIImage imageNamed:@"AudioChannel.png"];
    [thisbutton setImage:thisButtonImage forState:UIControlStateNormal];
    [kodiControlView addSubview:thisbutton];
}

+ (void)setVolumeValueChanging:(UISlider*)slider forEvent:(UIEvent*)event {
    [timer invalidate];
    [self setVolumeKodi:(float)slider.value];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(getKodiInfo) userInfo:nil repeats:YES];
    volumePercentageLabel.text = [NSString stringWithFormat:@"%i%%", (int)(100.0 * volumeSlider.value)];
}

+ (void)setPositionValueChanging:(UISlider*)slider forEvent:(UIEvent*)event {
    [timer invalidate];
    [self setPositionKodi:(float)slider.value];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(getKodiInfo) userInfo:nil repeats:YES];
    NSUInteger newTime = (long)((float)contentLengthInSeconds * positionSlider.value);
    contentTimeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self secondsToFormattedTime:newTime], totalTimeHumanReadable];
}

+ (void)DestroyKodiControlView
{
    [timer invalidate];
    [blockingView removeFromSuperview];
    [kodiControlView removeFromSuperview];
}

@end
