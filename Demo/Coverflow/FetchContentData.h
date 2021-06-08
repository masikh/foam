//
//  FetchContentData.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 10/12/2016.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#ifndef FetchContentData_h
#define FetchContentData_h


#endif /* FetchContentData_h */
@interface FetchContentData : NSObject
@property (atomic) NSMutableArray *MovieData;
@property (atomic) NSMutableArray *TVShowData;
@property (atomic) NSMutableArray *LiveTVData;
@property (atomic) NSString *AuthEmail;
@property (atomic) NSString *AuthPassword;
@property (nonatomic) NSString *languageID;

- (void)downloadMovieData :(BOOL)ssl :(NSString *)hostname;
- (void)downloadTVShowData :(BOOL)ssl :(NSString *)hostname;
- (void)downloadLiveTVData :(BOOL)ssl :(NSString *)hostname :(NSString *)username :(NSString *)password;
- (void)getLanguageID :(BOOL)ssl :(NSString *)hostname;
@end
