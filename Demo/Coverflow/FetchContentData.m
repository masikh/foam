//  FetchContentData.m
//  Created by Robert Nagtegaal on 10/12/2016.

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "FetchContentData.h"
#import "isReachable.h"

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface FetchContentData()
@property (nonatomic, strong) NSString *(^getLanguageID)(BOOL, NSString*);
@property (nonatomic) NSArray *channelTags;
@property (nonatomic) NSArray *allChannels;
@property (nonatomic) BOOL gotChannelTags;
@property (nonatomic) BOOL gotAllChannels;
@property (nonatomic) BOOL gotTVShowDetails;
@property (nonatomic) BOOL ssl;
@property (nonatomic) NSString *hostname;
@property (nonatomic) NSMutableArray *NewTVShowData;
@property (nonatomic) NSString *AuthToken;
@property (nonatomic) NSString *sha256_password;

@end

@implementation FetchContentData : NSObject
@synthesize channelTags;
@synthesize allChannels;
@synthesize languageID;
@synthesize gotChannelTags;
@synthesize gotAllChannels;
@synthesize gotTVShowDetails;
@synthesize ssl;
@synthesize hostname;
@synthesize NewTVShowData;
@synthesize AuthEmail;
@synthesize AuthPassword;
@synthesize sha256_password;

- (NSString*)md5HexDigest:(NSString*)input {
    const char* str = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str,(CC_LONG)strlen(str), digest);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",digest[i]];
    }
    return ret;
}

- (NSString *)buildUrl :(NSString *)filePath :(BOOL)ssl :(NSString *)mediaServer
{
    NSString *secret = @"s0m3th1n9unkn0wn";
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    
    NSString *basePath = [filePath stringByReplacingOccurrencesOfString:@"/libraries/" withString:@""];
    NSData *nsdata = [basePath dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    
    NSString *hash = [self md5HexDigest: [NSMutableString stringWithFormat:@"%@%@", base64Encoded, secret]];
    NSString *url = [NSMutableString stringWithFormat:@"%@://%@:7160/media/%@/%@", protocol, mediaServer, hash, base64Encoded];
    return url;
}

- (void)getLanguageID :(BOOL)ssl :(NSString *)hostname
{
    self.hostname = hostname;
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    NSMutableString *remoteUrl = [NSMutableString stringWithFormat:@"%@://%@/rest/languages/all/", protocol, hostname];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setLanguageID:) name:@"setLanguageID" object:self];
    [self aSyncRequestHandler:remoteUrl :ssl :@"setLanguageID"];
    
}

- (void)setLanguageID:(NSNotification *)notification
{
    NSArray *languages = (NSArray *) notification.userInfo;
    
    for (NSInteger i = languages.count - 1; i >= 0; i--) {
        NSString *language = [languages[i] valueForKey:@"isoCode1"];
        if ([language isEqualToString:@"en"]) {
            self->languageID = [languages[i] valueForKeyPath:@"id"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"gotLanguageID" object:nil];
        }
    }
    
}

- (void)downloadMovieData:(BOOL)ssl :(NSString *)hostname
{
    self.ssl = ssl;
    self.hostname = hostname;
    
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    NSMutableString *remoteUrl = [NSMutableString stringWithFormat:@"%@://%@/rest/api/movies/", protocol, hostname];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processMovieData:) name:@"processMovieData" object:self];
    [self aSyncRequestHandler:remoteUrl :ssl :@"processMovieData"];
    NSLog(@"Downloading metadata from %@", remoteUrl);
}

- (void)processMovieData:(NSNotification *)notification
{
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    
    NSArray *data = (NSArray *) notification.userInfo;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSMutableDictionary *element = nil;
    for (NSInteger i = data.count - 1; i >= 0; i--) {
        element = [data[i] mutableCopy];
        NSString *url = [self buildUrl: [element valueForKey:@"file_path"] :ssl :hostname];
        element[@"url"] = url;
        NSMutableArray *locale = [element valueForKey:@"locale_data"];
        for (NSInteger j = locale.count - 1; j >= 0; j--) {
            if ([[locale[j] valueForKey:@"language"] isEqualToString:languageID]) {
                NSString *poster = [locale[j] valueForKey:@"poster_url"];
                NSString *fanart = [locale[j] valueForKey:@"fanart_url"];
                NSString *plot = [locale[j] valueForKey:@"plot"];
                NSString *title = [locale[j] valueForKey:@"title"];
                NSString *directors = [[locale[j] valueForKey:@"directors"] componentsJoinedByString: @","];
                NSString *writers = [[locale[j] valueForKey:@"writers"] componentsJoinedByString: @","];
                NSString *genres = [[locale[j] valueForKey:@"genres"] componentsJoinedByString: @","];
                NSMutableArray *temp = [locale[j] valueForKey:@"actors"];
                NSMutableArray *actors = [[NSMutableArray alloc] init];
                for (NSInteger k = temp.count - 1; k >= 0; k--) {
                    NSString *name = [temp[k] valueForKey:@"name"];
                    NSString *role = [temp[k] valueForKey:@"role"];
                    NSString *picture = [NSMutableString stringWithFormat:@"%@://%@:7080/omnimage.jpg?id=%@&thumb=330x0", protocol, hostname, [temp[k] valueForKey:@"picture_url"]];
                    [actors addObject:@{@"name": name, @"role": role, @"picture_url": picture}];
                }
                element[@"actors"] = actors;
                actors = nil;
                element[@"thumb"] = [NSMutableString stringWithFormat:@"%@://%@:7080/omnimage.jpg?id=%@&thumb=500x0", protocol, hostname, poster];
                element[@"fanart"] = [NSMutableString stringWithFormat:@"%@://%@:7080/omnimage.jpg?id=%@&thumb=500x0", protocol, hostname, fanart];
                element[@"plot"] = [NSMutableString stringWithFormat:@"%@", plot];
                element[@"title"] = [NSMutableString stringWithFormat:@"%@", title];
                element[@"directors"] = [NSMutableString stringWithFormat:@"%@", directors];
                element[@"writers"] = [NSMutableString stringWithFormat:@"%@", writers];
                element[@"genres"] = [NSMutableString stringWithFormat:@"%@", genres];
            }
        }
        [result addObject:element];
    }
    // Set filtered results in MovieMetaDataObject
    self.MovieData = result;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadMetaDataComplete" object:nil];
    
    // Save result to NSUserDefaults
    NSError *error;
    NSData *movieData = [NSKeyedArchiver archivedDataWithRootObject:self.MovieData requiringSecureCoding:YES error:&error];
    [[NSUserDefaults standardUserDefaults] setObject:movieData forKey:@"MovieMetaDataObject"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Downloading movieMetaData done");
}

- (void)downloadTVShowDataDetails:(NSString *)TVShowID :(BOOL)ssl :(NSString *)hostname completionHandler:(void (^)(NSMutableDictionary *data))Completion
{
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    NSMutableString *url = [NSMutableString stringWithFormat:@"/rest/api/tvshows/%@/", TVShowID];
    NSString *API = [NSMutableString stringWithFormat:@"%@://%@%@", protocol, hostname, url];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString:API]];
    NSURLSession *session = [NSURLSession sharedSession];
    [req setValue:self.AuthToken forHTTPHeaderField:@"token"];
    [req setValue:@"*/*" forHTTPHeaderField:@"accept"];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Downloaded tvshow details for: %@", TVShowID);
        NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        Completion(dict);
    }];
    [dataTask resume];
}

- (void)getSeasonsAndEpisodes :(NSString *)TVShowID :(BOOL)ssl :(NSString *)hostname completionHandler:(void (^)(NSMutableArray *data))Completion
{
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    NSString *url = [NSMutableString stringWithFormat:@"/rest/seasons/list/?tvshowid=%@", TVShowID];
    NSString *API = [NSMutableString stringWithFormat:@"%@://%@%@", protocol, hostname, url];
    
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:API];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:API]];
    NSURLSession *session = [NSURLSession sharedSession];
    [request setValue:self.AuthToken forHTTPHeaderField:@"token"];
    [request setValue:@"*/*" forHTTPHeaderField:@"accept"];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                @try {
                    NSMutableArray *seasonsData = (NSMutableArray *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    NSMutableArray *episodes = [[NSMutableArray alloc] init];;
                    NSMutableArray *seasons = [[NSMutableArray alloc] init];
                    NSMutableArray *completed = [[NSMutableArray alloc] init];
                    NSMutableDictionary *season = nil;
                    for (NSInteger i = seasonsData.count - 1; i >= 0; i--) {
                        season = [seasonsData[i] mutableCopy];
                        NSString *url = [NSMutableString stringWithFormat:@"/rest/episodes/list/?seasonid=%@", [seasonsData[i] valueForKey:@"id"]];
                        NSString *API = [NSMutableString stringWithFormat:@"%@://%@%@", protocol, hostname, url];
                        
                        [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:API];
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:API]];
                        NSURLSession *session = [NSURLSession sharedSession];
                        [request setValue:self.AuthToken forHTTPHeaderField:@"token"];
                        [request setValue:@"*/*" forHTTPHeaderField:@"accept"];
                        
                        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                {
                                    @try {
                                        NSMutableArray *result = (NSMutableArray *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                        NSMutableDictionary *element = nil;
                                        for (NSInteger i = result.count - 1; i >= 0; i--) {
                                            element = [result[i] mutableCopy];
                                            NSString *url = [self buildUrl: [element valueForKey:@"file_path"] :ssl :hostname];
                                            element[@"url"] = url;
                                            [episodes addObject:element];
                                        }
                                        
                                        season[@"episodes"] = episodes;
                                        [seasons addObject:season];
                                        
                                        [completed addObject:[NSString stringWithFormat:@"%ld", i]];
                                        if (completed.count == seasonsData.count) {
                                            Completion(seasons);
                                        }
                                    } @catch (NSException *exception) {
                                        NSLog(@"%@", exception);
                                    }
                        }];
                        [dataTask resume];
                    }
                } @catch (NSException *exception) {
                    NSLog(@"%@", exception);
                }
            }];
    [dataTask resume];
}

- (void)downloadTVShowData :(BOOL)ssl :(NSString *)hostname
{
    self.ssl = ssl;
    self.hostname = hostname;
    
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    NSString *query_options = [NSMutableString stringWithFormat:@"?current_page=1&current_search=&current_sort=_id&current_state=&entry_limit=200000&language=%@&library=TVShows&reverse=true", languageID];
    NSMutableString *remoteUrl = [NSMutableString stringWithFormat:@"%@://%@/rest/getTVShowsMetadataList/%@", protocol, hostname, query_options];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processTVShowData:) name:@"processTVShowData" object:self];
    [self aSyncRequestHandler:remoteUrl :false :@"processTVShowData"];
}

- (void)processTVShowData:(NSNotification *)notification
{
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    
    NewTVShowData = [(NSArray *) notification.userInfo mutableCopy];
    NSMutableArray *completed = [[NSMutableArray alloc] init];
    for (NSInteger i = NewTVShowData.count - 1; i >= 0; i--) {
        gotTVShowDetails = false;
        NewTVShowData[i] = [NewTVShowData[i] mutableCopy];
        // Set poster
        NSString *poster = [NSMutableString stringWithFormat:@"%@://%@:7080/omnimage.jpg?id=%@&thumb=500x0", protocol, hostname, [NewTVShowData[i] valueForKeyPath:@"poster_url"]];
        [NewTVShowData[i] setValue:poster forKey:@"poster"];
        
        // Get TVShow details
        [self downloadTVShowDataDetails :[NewTVShowData[i] valueForKeyPath:@"_id"] :ssl :hostname completionHandler:^(NSMutableDictionary *data) {
            [self.NewTVShowData[i] setValue:data forKey:@"TVShowdetail"];
            
            // Download Seasons and Episodes
            // NSMutableArray *seasonsAndEpisodes = [self getSeasonsAndEpisodes :[self->NewTVShowData[i] valueForKeyPath:@"_id.$oid"] :self->ssl :self->hostname];
            
            [self getSeasonsAndEpisodes :[self->NewTVShowData[i] valueForKeyPath:@"_id"] :self->ssl :self->hostname completionHandler:^(NSMutableArray *seasonsAndEpisodes) {
                [self.NewTVShowData[i] setValue:seasonsAndEpisodes forKey:@"seasons_episodes"];
                
                [completed addObject:[NSString stringWithFormat:@"%ld", i]];
                NSLog(@"completed: %ld of %ld", completed.count, self->NewTVShowData.count);
                if (completed.count == self->NewTVShowData.count) {
                    self.TVShowData = [self.NewTVShowData copy];
                    // Save result to NSUserDefaults
                    NSData *tvshowData = [NSKeyedArchiver archivedDataWithRootObject:self.TVShowData requiringSecureCoding:YES error:nil];
                    [[NSUserDefaults standardUserDefaults] setObject:tvshowData forKey:@"TVShowMetaDataObject"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadMetaDataComplete" object:nil];
                }
            }];
        }];
    }
}

- (void)sha256HashFor:(NSString*)text {
    const char* utf8chars = [text UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(utf8chars, (CC_LONG)strlen(utf8chars), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    sha256_password = ret;
}

- (void)aSyncRequestHandler:(NSString *)url :(BOOL)ssl :(NSString *)callback
{
    self.ssl = ssl;
    self.hostname = hostname;
    
    NSString *protocol = @"http";
    if (ssl) protocol = @"https";
    NSMutableString *AuthUrl = [NSMutableString stringWithFormat:@"%@://%@:10103/user/signin", protocol, hostname];
    
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:url];
    NSMutableURLRequest *tokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:AuthUrl]];
    NSURLSession *session = [NSURLSession sharedSession];
    
    // Create a post request
    [tokenRequest setHTTPMethod:@"POST"];
    
    // Set request header
    [tokenRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [tokenRequest setValue:@"*/*" forHTTPHeaderField:@"accept"];
    
    if (sha256_password == nil) {
        [self sha256HashFor:AuthPassword];
    };
    
    NSMutableDictionary *postValue = [[NSMutableDictionary alloc] init];
    [postValue setValue:AuthEmail forKey:@"email"];
    [postValue setValue:sha256_password forKey:@"password"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postValue options:0 error:nil];
    tokenRequest.HTTPBody = jsonData;
    
    NSLog(@"Requesting TOKEN: %@", AuthUrl);
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:tokenRequest
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
            {
                @try {
                    NSMutableDictionary *token_dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    
                    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:url];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
                    NSURLSession *session = [NSURLSession sharedSession];
                    
                    // Set request header
                    self.AuthToken = [token_dict valueForKey:@"accessToken"];
                    NSLog(@"Token Acquired: %@", self.AuthToken);
                    [request setValue:self.AuthToken forHTTPHeaderField:@"token"];
                    [request setValue:@"*/*" forHTTPHeaderField:@"accept"];
                    
                    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                            {
                                @try {
                                    NSLog(@"calling: %@", url);
                                    NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                    if (dict == nil) { NSLog(@"No data returned :("); };
                                    [[NSNotificationCenter defaultCenter] postNotificationName:callback object:self userInfo:dict];
                                } @catch (NSException *exception) {
                                    NSLog(@"%@", exception);
                                }
                            }];
                    [dataTask resume];
                } @catch (NSException *exception) {
                    NSLog(@"%@", exception);
                }
            }];
    [dataTask resume];
}

- (void)requestChannelTags:(NSString *) hostname :(NSString *) username :(NSString *) password
{
    NSMutableString *remoteUrl = [NSMutableString stringWithFormat:@"http://%@:%@@%@:9981/api/channeltag/list", username, password, hostname];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setChannelTags:) name:@"setChannelTags" object:self];
    [self aSyncRequestHandler:remoteUrl :false :@"setChannelTags"];
}
    
- (void)setChannelTags:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSMutableArray *tags = [[NSMutableArray alloc] init];
    NSArray *tmp = [dict valueForKeyPath:@"entries"];
    NSMutableArray *keep = [NSMutableArray arrayWithObjects:@"SKY", @"MTV Networks Europe", @"FOXGE", @"GLOBECAST", @"FOXNWS", @"Movistar", @"CBC", @"*** Canal Digitaal HD", @"CANAL +", @"*** TV Vlaanderen HD", @"Telekom Srbija", nil];
    for (int i = 0; i < tmp.count; i++) {
        if ([keep containsObject:[tmp[i] valueForKeyPath:@"val"]]) {
            NSString *identifier = [tmp[i] objectForKey:@"key"];
            [tags addObject:identifier];
        }
    }
    channelTags = [tags mutableCopy];
    gotChannelTags = true;
}

- (void)requestChannels:(NSString *) hostname :(NSString *) username :(NSString *) password
{
    NSMutableString *remoteUrl = [NSMutableString stringWithFormat:@"http://%@:%@@%@:9981/api/channel/grid?limit=10000", username, password, hostname];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAllChannels:) name:@"setAllChannels" object:self];
    [self aSyncRequestHandler:remoteUrl :false :@"setAllChannels"];
}

- (void)setAllChannels:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    allChannels = [dict valueForKeyPath:@"entries"];
    gotAllChannels = true;
}

- (bool)isDigitOnly:(NSString *)str
{
    NSUInteger len = [str length];
    unichar buffer[len+1];
    [str getCharacters:buffer range:NSMakeRange(0, len)];
    for(int i = 0; i < len; i++) {
        if (buffer[i] < '0' || buffer[i] > '9')
            return false;
    }
    return true;
}

- (void)downloadLiveTVData:(BOOL) ssl :(NSString *) hostname :(NSString *) username :(NSString *) password
{
    gotAllChannels = false;
    gotChannelTags = false;
    [self requestChannelTags:hostname :username :password];
    [self requestChannels:hostname :username :password];
    NSDate *then_date = [NSDate date];
    NSTimeInterval then = [then_date timeIntervalSince1970];
    
    if (!self->gotAllChannels || !self->gotChannelTags) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            bool stop = false;
            while ((!self->gotAllChannels || !self->gotChannelTags) && !stop) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((0.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSLog(@"Waiting for LiveTVData");
                });
                [NSThread sleepForTimeInterval:0.1];//check again if it's loaded every 0.1s
                
                // bail out after 10s.
                NSDate *now_date = [NSDate date];
                NSTimeInterval now = [now_date timeIntervalSince1970];
                if (now - then > 10.0) stop = true;
            }

            dispatch_sync(dispatch_get_main_queue(), ^{
                dispatch_semaphore_signal(semaphore);
            });

        });
        
        
        bool stop = false;
        
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW) && !stop) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            
            // bail out after 10s.
            NSDate *now_date = [NSDate date];
            NSTimeInterval now = [now_date timeIntervalSince1970];
            if (now - then > 10.0) stop = true;
        }
    }
    
    if (!self->gotAllChannels && !self->gotChannelTags) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadMetaDataComplete" object:nil];
        return;
    }
    
    NSMutableArray *newChannels = [[NSMutableArray alloc] init];
    NSMutableArray *omitList = [NSMutableArray arrayWithObjects:@"", @".", @"RADIO", nil];
    
    for (int i = 0; i < allChannels.count; i++) {
        @try {
            NSArray *tags = [[NSArray alloc] initWithArray:[allChannels[i] valueForKeyPath:@"tags"]];
            for (int j = 0; j < tags.count; j++) {
                if ([channelTags containsObject:tags[j]]) {
                    NSString *channelname = [allChannels[i] valueForKeyPath:@"name"];
                    if (![omitList containsObject:[channelname uppercaseString]]) {
                        if (![self isDigitOnly:channelname]) {
                            NSArray *service_ids = [allChannels[i] valueForKeyPath:@"services"];
                            NSString *url = [NSMutableString stringWithFormat:@"/play/stream/service/%@", service_ids[0]];
                            NSString *logo = [NSMutableString stringWithFormat:@"http://%@:%@@%@:9981/%@", username, password, hostname, [allChannels[i] valueForKeyPath:@"icon_public_url"]];
                            [newChannels insertObject:@{@"name": channelname, @"url": url, @"logo": logo} atIndex:0];
                        }
                    }
                }
            }
        }
        @catch (NSException * e) {
            NSLog(@"FetchContentData.downloadLiveTVData %@", e);
        }
    }
    // Save result to NSUserDefaults
    NSData *livetvData = [NSKeyedArchiver archivedDataWithRootObject:newChannels requiringSecureCoding:YES error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:livetvData forKey:@"LiveTVMetaDataObject"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.LiveTVData = [newChannels mutableCopy];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadMetaDataComplete" object:nil];
}

@end
