//
//  MetaDataView.m
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 15/04/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <SDWebImageManager.h>
#import "ImageLoader.h"
#import "MetaDataViewMovies.h"

//@interface MetaDataViewMovies() <UITableViewDelegate,UITableViewDataSource>
@interface MetaDataViewMovies() <UITableViewDelegate>
@end

@implementation MetaDataViewMovies

// For sending a param via a button
NSArray *actorsMovie;
UITableView *tableMovies;
NSString *trailerId;
UIView *masterView;
UIView *slaveView;
NSString *_kodiUsername;
NSString *_kodiPassword;
NSString *_kodiHostname;


+ (void)ContentMetaDataViewMovies:(UIView*)thisView :(CDemoCollectionViewCell*)theCell :(NSIndexPath *)pressedIndexPath :(NSIndexPath *)theIndexPath :(NSMutableArray*)MetaData {
    masterView = thisView;
    // Device width (the size of the canvas!)
    CGFloat deviceWidth = thisView.frame.size.width;
    CGFloat deviceHeight = thisView.frame.size.height;
    
    UIView *blockingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thisView.frame.size.width, thisView.frame.size.height)];
    blockingView.tag = 70;
    [thisView addSubview:blockingView];
    UIView *ContentMetaDataView = [[UIView alloc] init];
    CGRect ContentMetaDataViewMoviesRect = [self ContentMetaDataViewMoviesRect:(float)deviceWidth :(float)deviceHeight];
    [ContentMetaDataView setFrame:ContentMetaDataViewMoviesRect];
    ContentMetaDataView.layer.borderWidth = 2.0f;
    ContentMetaDataView.layer.borderColor = [[UIColor grayColor] CGColor];
    ContentMetaDataView.layer.cornerRadius = 5;
    [ContentMetaDataView.layer setMasksToBounds:YES];
    ContentMetaDataView.tag = 70;
    
    ContentMetaDataView.backgroundColor = [UIColor clearColor];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = ContentMetaDataView.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.layer.cornerRadius = 5;
    blurEffectView.tag = 70;
    blurEffectView.alpha = 0.95f;
    [blurEffectView.layer setMasksToBounds:YES];
    [blockingView addSubview:ContentMetaDataView];
    [ContentMetaDataView addSubview:blurEffectView];
    [self BuildContentMetaDataViewMovies:blurEffectView :theCell :MetaData :pressedIndexPath :ContentMetaDataView];
}

+ (CGRect)ContentMetaDataViewMoviesRect:(float)width :(float)height
{
    CGRect thisRect;
    switch ((int)width) {
        case 480:
        case 568:
            thisRect = CGRectMake(10, 10, width - 20, height - 20);
            break;
        case 1024:
            thisRect = CGRectMake(20, 58, width - 40, height - 93); // ipad mini
            break;
        default:
            thisRect = CGRectMake(20, 58, width - 40, height - 93);
            break;
    }
    return thisRect;
}

+ (void)BuildContentMetaDataViewMovies:(UIVisualEffectView*)thisView :(CDemoCollectionViewCell*)theCell :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath :(UIView*)ContentMetaDataView
{
    slaveView = ContentMetaDataView;
    [self SetImageMovies:ContentMetaDataView :theCell :MetaData :pressedIndexPath];
    [self SetTitleMovies:ContentMetaDataView :MetaData :pressedIndexPath];
    [self SetPlotMovies:ContentMetaDataView :MetaData :pressedIndexPath];
    // [self SetAdditionalInfoMovies:ContentMetaDataView :MetaData :pressedIndexPath];
    [self SetBackButtonMovies:ContentMetaDataView];
    [self SetMovieButton:ContentMetaDataView :MetaData :pressedIndexPath];
    [self SetTrailerButtonMovies:ContentMetaDataView :MetaData :pressedIndexPath];
    //[self SetKodiButtonMovies:ContentMetaDataView :MetaData :pressedIndexPath];
    [self SetInfoPane:ContentMetaDataView :MetaData :pressedIndexPath];
    [self SetKodiRemoteControl:ContentMetaDataView];
}

+ (void)SetInfoPane:(UIView*)thisView :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat width = thisView.frame.size.width;
    CGFloat height = thisView.frame.size.height;
    
    UIView *Info;
    Info = [[UIButton alloc]initWithFrame:CGRectMake(224 + (0.25 * width), -40 + (0.666 * height), 80, 39)];
    Info.backgroundColor = [UIColor colorWithRed:224.0/255.0f green:168.0/255.0f blue:12.0/255.0f alpha:1.0];
    Info.layer.cornerRadius = 2.0;
    
    [thisView addSubview:Info];
    
    // Kodi blue: colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0
    UIColor *textColor = [UIColor darkGrayColor];
    UILabel *durationLabel;
    UIButton *ratingButton;

    ratingButton = [[UIButton alloc] initWithFrame:CGRectMake(228 + (0.25 * width), 20 + height * 0.5, 100, 10)];
    durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(228 + (0.25 * width), 30 + height * 0.5, 100, 10)];
        
    ratingButton.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: 8];
    durationLabel.font = [UIFont fontWithName:@"Helvetica" size:8];
        
    // Get Rating, Runtime, Director, Writer and Genres
    NSString *rating = [MetaData[pressedIndexPath.item] objectForKey:@"rating"];
    NSString *duration = [MetaData[pressedIndexPath.item] objectForKey:@"duration"];
    
    NSMutableAttributedString *ratingString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat: @"Rating: %@ (tmdb)", rating]];
    [ratingString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, [ratingString length])];
    [ratingButton setAttributedTitle:ratingString forState:UIControlStateNormal];
    ratingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    durationLabel.text = [NSString stringWithFormat:@"Duration: %@ min.", duration];
    
    ratingButton.tag = 70;          ratingButton.titleLabel.textColor = textColor;
    durationLabel.tag = 70;         durationLabel.textColor = textColor;
    ratingButton.backgroundColor = [UIColor clearColor];
    
    [thisView addSubview:ratingButton];
    [thisView addSubview:durationLabel];
}

+ (void)SetPlotMovies:(UIView*)thisView :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat width = thisView.frame.size.width;
    CGFloat height = thisView.frame.size.height;
    UITextView *Synopsis;
    
    // [[UITextView alloc] initWithFrame:CGRectMake(25 + (0.25 * width), -15 + (0.666 * height) , -25 + (0.75 * 548), 50)];
    
    Synopsis = [[UITextView alloc] initWithFrame:CGRectMake(25 + (0.25 * width), 25 + (0.666 * height), -30 + (0.75 * width), 70)];
    Synopsis.font = [UIFont fontWithName:@"Helvetica" size:12];
    
    // Kodi blue: colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0
    UIColor *textColor = [UIColor colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0];
    
    Synopsis.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
    Synopsis.layer.masksToBounds = YES;
    Synopsis.selectable = NO;
    Synopsis.layer.borderColor = [[UIColor clearColor] CGColor];
    Synopsis.backgroundColor = [UIColor clearColor];
    Synopsis.editable = NO;
    Synopsis.alpha = 1.0f;
    Synopsis.textColor = textColor;
    Synopsis.textAlignment = NSTextAlignmentJustified;
    [Synopsis setText:[NSString stringWithFormat:@"%@", [MetaData[pressedIndexPath.item] objectForKey:@"plot"]]];
    Synopsis.tag = 70;
    [thisView addSubview:Synopsis];
}

+ (void)SetBackButtonMovies:(UIView*)thisView
{
    // Set Back Button
    UIButton *thisbutton;
    if (thisView.frame.size.width == 548) {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake(thisView.frame.size.width - 60, 0, 50, 50)];
    } else {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake(thisView.frame.size.width - 90, 0, 80, 80)];
    }
    [thisbutton addTarget:self action:@selector(DestroyContentMetaDataViewMovies) forControlEvents:UIControlEventTouchUpInside];
    UIImage *thisButtonImage = [UIImage imageNamed:@"back3.png"];
    [thisbutton setImage:thisButtonImage forState:UIControlStateNormal];
    [thisView addSubview:thisbutton];
    thisbutton.tag = 70;
}

+ (void)SetImageMovies:(UIView*)thisView :(CDemoCollectionViewCell*)theCell :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath {
    CGFloat height = thisView.frame.size.height;
    CGFloat width = thisView.frame.size.width;
    
    // Set the coverflow picture for this content item
    NSURL *fanart_url = [NSURL URLWithString: [MetaData[pressedIndexPath.item] objectForKey:@"fanart"]];
    UIImageView *fanart = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    fanart.tag = 70;
    
    [ImageLoader loadImage:[MetaData[pressedIndexPath.item] objectForKey:@"fanart"] :fanart];
    if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[fanart_url absoluteString]]) {
        fanart.image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[fanart_url absoluteString]];
        
    } else {
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:[fanart_url absoluteString]])
        {
            // Set cached thumbnail image on imageview
            fanart.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[fanart_url absoluteString]];
        }
    }
    
    NSURL *thumb_url = [NSURL URLWithString: [MetaData[pressedIndexPath.item] objectForKey:@"thumb"]];
    UIImageView *thumb = [[UIImageView alloc] initWithFrame:CGRectMake(20, height / 4, width / 4, (width / 4) * 1.5)];
    thumb.layer.cornerRadius = 5.0;
    thumb.layer.masksToBounds = YES;
    thumb.layer.borderColor = [UIColor lightGrayColor].CGColor;
    thumb.layer.borderWidth = 1.0;
    thumb.tag = 70;
    
    [ImageLoader loadImage:[MetaData[pressedIndexPath.item] objectForKey:@"thumb"] :fanart];
    if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[thumb_url absoluteString]]) {
        thumb.image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[thumb_url absoluteString]];
        
    } else {
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:[thumb_url absoluteString]])
        {
            // Set cached thumbnail image on imageview
            thumb.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[thumb_url absoluteString]];
        }
    }
    
    UIView *infoPane = [[UIView alloc] initWithFrame:CGRectMake(0, 55 + height * 0.5, width, height * 0.5)];
    infoPane.backgroundColor = [UIColor colorWithRed:30.0/255.0f green:72.0/255.0f blue:101.0/255.0f alpha:0.8];
    infoPane.tag = 70;
    
    [thisView addSubview:fanart];
    [thisView addSubview:infoPane];
    [thisView addSubview:thumb];
}

+ (void)SetTitleMovies:(UIView*)thisView :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat height = thisView.frame.size.height;
    CGFloat width = thisView.frame.size.width;
    
    UITextView *contentTitle;
    contentTitle = [[UITextView alloc] initWithFrame:CGRectMake(25 + (0.25 * width), (0.666 * height), -25 + (0.75 * width), 50)];
    contentTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];

    // Kodi blue: colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0
    UIColor *TitleColor = [UIColor colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0];
    NSString *title = [NSString stringWithFormat:@"%@", [MetaData[pressedIndexPath.item] objectForKey:@"title"]];
    NSString *originalTitle = [NSString stringWithFormat:@"%@", [MetaData[pressedIndexPath.item] objectForKey:@"original_title"]];
    NSString *fullTitle;
    
    if ([title isEqualToString:@"(null)"]) {
        fullTitle = [NSString stringWithFormat:@"%@", originalTitle];
    } else {
        fullTitle = title;
    }
    
    contentTitle.textContainer.maximumNumberOfLines = 1;
    contentTitle.layer.masksToBounds = YES;
    contentTitle.layer.borderColor = [[UIColor clearColor] CGColor];
    contentTitle.backgroundColor = [UIColor clearColor];
    contentTitle.alpha = 1.0f;
    contentTitle.textColor = TitleColor;
    contentTitle.editable = NO;
    contentTitle.selectable = NO;
    contentTitle.text = fullTitle;
    [contentTitle.layoutManager textContainerChangedGeometry:contentTitle.textContainer];
    [thisView addSubview:contentTitle];
}

+ (void)SetMovieButton:(UIView*)thisView :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat height = thisView.frame.size.height;
    CGFloat width = thisView.frame.size.width;
    
    UIButton *MovieButton;
    MovieButton = [[UIButton alloc]initWithFrame:CGRectMake(30 + (0.25 * width), -40 + (0.666 * height), 80, 40)];
    
    // Set a MovieButton for (lovel lower corner right of Trailerbutton: Movies.png)
    UIImage *MovieButtonImage = [UIImage imageNamed:@"play-yellow.png"];
    MovieButton.tag = 69;
    [MovieButton setImage:MovieButtonImage forState:UIControlStateNormal];
    [MovieButton addTarget:self action:@selector(startMovie) forControlEvents:UIControlEventTouchUpInside];
    [thisView addSubview:MovieButton];
}

+ (void)SetTrailerButtonMovies:(UIView*)thisView :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat height = thisView.frame.size.height;
    CGFloat width = thisView.frame.size.width;
    
    UIButton *TrailerButton;
    TrailerButton = [[UIButton alloc]initWithFrame:CGRectMake(126 + (0.25 * width), -40 + (0.666 * height), 80, 40)];
    NSArray *trailers = [MetaData[pressedIndexPath.item] objectForKey:@"trailers"];
    if (trailers.count > 0) {
        trailerId = [NSString stringWithFormat:@"%@", [trailers[0] objectForKey:@"key"]];
    } else {
        trailerId = @"";
    }
    
    // Set a TrailerButton for (lovel lower corner right of backbutton: Trailer.png)
    UIImage *TrailerButtonImage = [UIImage imageNamed:@"play-yellow-trailer.png"];
    TrailerButton.tag = 69;
    [TrailerButton setImage:TrailerButtonImage forState:UIControlStateNormal];
    [TrailerButton addTarget:self action:@selector(startTrailerMovie) forControlEvents:UIControlEventTouchUpInside];
    [thisView addSubview:TrailerButton];
}

+ (void)SetKodiRemoteControl:(UIView*)thisView
{
    CGFloat height = thisView.frame.size.height;
    CGFloat width = thisView.frame.size.width;
    
    UIButton *kodiControl;
    kodiControl = [[UIButton alloc]initWithFrame:CGRectMake(320 + (0.25 * width), -40 + (0.666 * height), 80, 40)];
    
    UIImage *kodiControlImage = [UIImage imageNamed:@"remote-yellow-kodi.png"];
    kodiControl.tag = 69;
    [kodiControl setImage:kodiControlImage forState:UIControlStateNormal];
    [kodiControl addTarget:self action:@selector(remoteControlKODIView) forControlEvents:UIControlEventTouchUpInside];
    [thisView addSubview:kodiControl];
}

+ (void)remoteControlKODIView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteControlKODIView" object:nil];
}

+ (void)startMovie
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startMovie" object:nil];
}

+ (void)startTrailerMovie
{    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startTrailerMovie" object:nil];
}

+ (void)DestroyContentMetaDataViewMovies
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DestroyContentMetaDataView" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"startMovie" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"startTrailer" object:nil];
}

@end
