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
#import "MetaDataViewTVShows.h"
#import "VideoPlayerViewController.h"

@interface MetaDataViewTVShows() <UITableViewDelegate,UITableViewDataSource>
@end

@implementation MetaDataViewTVShows

NSArray *actorsTVShow;
NSArray *episodesTVShow;
UITableView *tableTVShows;
UITableView *tableContentView;
UIView *blurView;
NSString *server;
NSString *protocol;
NSURL *contentURL;

// Views for all metadata and episodes
UIView *ContentMetaDataView;
UIView *infoPane;
UIView *infoBlokBar;
UIButton *TrailerButton;
UIButton *kodiControlButton;
UITextView *contentTitle;
UITextView *Synopsis;
UILabel *runtimeLabel;
UILabel *seasonsLabel;
UILabel *genreLabel;
UILabel *durationLabel;
UILabel *ratingLabel;
UIButton *switcher;

bool seasonsview = false;

+ (void)ContentMetaDataViewTVShows:(UIView*)thisView :(CDemoCollectionViewCell*)theCell :(NSIndexPath *)pressedIndexPath :(NSIndexPath *)theIndexPath :(NSMutableArray*)MetaDataTVShow :(NSString*)hostname :(bool)ssl :(NSURL*)currentTVShowURL
{
    // Set hostname and protocol for image retrieval etc...
    server = [[NSString alloc] initWithString:hostname];
    protocol = @"http://";
    if (ssl) {
        protocol = @"https://";
    }
    contentURL = currentTVShowURL;

    // Device width (the size of the canvas!)
    CGFloat deviceWidth = thisView.frame.size.width;
    CGFloat deviceHeight = thisView.frame.size.height;
    
    UIView *blockingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thisView.frame.size.width, thisView.frame.size.height)];
    blockingView.tag = 70;
    [thisView addSubview:blockingView];
    ContentMetaDataView = [[UIView alloc] init];
    CGRect ContentMetaDataViewTVShowsRect = [self ContentMetaDataViewTVShowsRect:(float)deviceWidth :(float)deviceHeight];
    [ContentMetaDataView setFrame:ContentMetaDataViewTVShowsRect];
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
    [self BuildContentMetaDataViewTVShows:theCell :MetaDataTVShow :pressedIndexPath];
}

+ (CGRect)ContentMetaDataViewTVShowsRect:(float)width :(float)height
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

+ (void)BuildContentMetaDataViewTVShows:(CDemoCollectionViewCell*)theCell :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    [self SetImageTVShows:theCell :MetaData :pressedIndexPath];
    [self SetTitleTVShows:MetaData :pressedIndexPath];
    [self SetBackButtonTVShows];
    [self SetPlotTVShows:MetaData :pressedIndexPath];
    [self SetTrailerButtonTVShows:MetaData :pressedIndexPath];
    [self SetInfoPane:MetaData :pressedIndexPath];
    [self SetKodiRemoteControl];
    [self SetBlurView];
    //[self SetActorsTVShows:MetaData :pressedIndexPath];
    [self episodeListTVShows:MetaData :pressedIndexPath];
}

+ (void)SetBlurView
{
    CGFloat width = ContentMetaDataView.frame.size.width;
    CGFloat height = ContentMetaDataView.frame.size.height;
    
    blurView = [[UIView alloc] initWithFrame:CGRectMake(30 + (0.25 * width), height / 4, -45 + (0.75 * width), (width / 4) * 1.5)];
    blurView.backgroundColor = [UIColor colorWithRed:30.0/255.0f green:72.0/255.0f blue:101.0/255.0f alpha:0.8];

    blurView.layer.cornerRadius = 5.0;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = blurView.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.layer.cornerRadius = 5;
    blurEffectView.tag = 70;
    blurEffectView.alpha = 0.70f;
    [blurEffectView.layer setMasksToBounds:YES];
    //[blurView addSubview:blurEffectView];
}

+ (void)SetInfoPane:(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat width = ContentMetaDataView.frame.size.width;
    CGFloat height = ContentMetaDataView.frame.size.height;
    
    infoPane = [[UIButton alloc]initWithFrame:CGRectMake(130 + (0.25 * width), -40 + (0.666 * height), 80, 39)];
    infoPane.backgroundColor = [UIColor colorWithRed:224.0/255.0f green:168.0/255.0f blue:12.0/255.0f alpha:1.0];
    infoPane.layer.cornerRadius = 2.0;
    
    [ContentMetaDataView addSubview:infoPane];
    
    // Kodi blue: colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0
    UIColor *textColor = [UIColor darkGrayColor];
    
    ratingLabel = [[UILabel alloc] initWithFrame:CGRectMake(133 + (0.25 * width), 20 + height * 0.5, 100, 10)];
    durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(133 + (0.25 * width), 30 + height * 0.5, 100, 10)];
        
    ratingLabel.font = [UIFont fontWithName: @"Helvetica" size: 8];
    durationLabel.font = [UIFont fontWithName:@"Helvetica" size:8];
        
    // Get Rating, Runtime, Director, Writer and Genres
    NSString *ratingDouble = [MetaData[pressedIndexPath.item] valueForKeyPath:@"TVShowdetail.rating"];
    NSString *rating = [NSString stringWithFormat:@"%d.1", ratingDouble.intValue];
    NSString *durationDouble = [MetaData[pressedIndexPath.item] objectForKey:@"runtime"];
    NSString *duration = [NSString stringWithFormat:@"%d.1", durationDouble.intValue];
    
    durationLabel.text = [NSString stringWithFormat:@"Duration: %@ min.", duration];
    durationLabel.tag = 70;         durationLabel.textColor = textColor;
    ratingLabel.text = [NSString stringWithFormat: @"Rating: %@", rating];
    durationLabel.tag = 70;         durationLabel.textColor = textColor;
    ratingLabel.tag = 70;           ratingLabel.textColor = textColor;
    
    [ContentMetaDataView addSubview:ratingLabel];
    [ContentMetaDataView addSubview:durationLabel];
}


+ (void)SetTrailerButtonTVShows:(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat height = ContentMetaDataView.frame.size.height;
    CGFloat width = ContentMetaDataView.frame.size.width;
    
    TrailerButton = [[UIButton alloc]initWithFrame:CGRectMake(30 + (0.25 * width), -40 + (0.666 * height), 80, 40)];
    
    // Set a TrailerButton for (lovel lower corner right of backbutton: Trailer.png)
    UIImage *TrailerButtonImage = [UIImage imageNamed:@"play-yellow-trailer.png"];
    TrailerButton.tag = 69;
    [TrailerButton setImage:TrailerButtonImage forState:UIControlStateNormal];
    [TrailerButton addTarget:self action:@selector(startTrailerTVShow) forControlEvents:UIControlEventTouchUpInside];
    [ContentMetaDataView addSubview:TrailerButton];
}

+ (void)SetKodiRemoteControl
{
    CGFloat height = ContentMetaDataView.frame.size.height;
    CGFloat width = ContentMetaDataView.frame.size.width;
    
    kodiControlButton = [[UIButton alloc]initWithFrame:CGRectMake(230 + (0.25 * width), -40 + (0.666 * height), 80, 40)];
    
    UIImage *kodiControlImage = [UIImage imageNamed:@"remote-yellow-kodi.png"];
    kodiControlButton.tag = 69;
    [kodiControlButton setImage:kodiControlImage forState:UIControlStateNormal];
    [kodiControlButton addTarget:self action:@selector(remoteControlKODIView) forControlEvents:UIControlEventTouchUpInside];
    [ContentMetaDataView addSubview:kodiControlButton];
}

+ (void)remoteControlKODIView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteControlKODIView" object:nil];
}


+ (void)startTrailerTVShow
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startTrailerTVShow" object:nil];
}

+ (void)episodeListTVShows:(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat width = blurView.frame.size.width;
    CGFloat height = blurView.frame.size.height;
    
    // Create a list of all episodes of all seasons...
    NSArray *Seasons = [MetaData[pressedIndexPath.item] valueForKeyPath:@"seasons_episodes"];
    NSMutableArray *episodes = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < Seasons.count; i++) {
        NSMutableArray *temp  = [Seasons[i] valueForKeyPath:@"episodes"];
        for (int j = 0; j < temp.count; j++) {
            [episodes addObject:temp[j]];
        }
    }
    episodesTVShow = episodes;
    episodes = nil;
    
    tableContentView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, width - 20, height - 20) style:UITableViewStylePlain];
    tableContentView.delegate = MetaDataViewTVShows.self;
    tableContentView.dataSource = MetaDataViewTVShows.self;
    tableContentView.backgroundColor = [UIColor clearColor];
    tableContentView.layer.backgroundColor = [[UIColor clearColor] CGColor];
    tableContentView.allowsSelection = NO;
}

+ (void)SetActorsTVShows:(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat width = ContentMetaDataView.frame.size.width;
    CGFloat height = ContentMetaDataView.frame.size.height;
    
    actorsTVShow = [MetaData[pressedIndexPath.item] valueForKeyPath:@"actors"];
    if (width == 548) {
        tableTVShows = [[UITableView alloc] initWithFrame:CGRectMake((height * 2 / 3) + 20, 102, width - (height * 2 / 3) - 37, 156) style:UITableViewStylePlain];
    } else {
        tableTVShows = [[UITableView alloc] initWithFrame:CGRectMake((height * 2 / 3) + 11, 186, width - (height * 2 / 3) - 33, 261) style:UITableViewStylePlain];
    }
    tableTVShows.delegate = MetaDataViewTVShows.self;
    tableTVShows.dataSource = MetaDataViewTVShows.self;
    tableTVShows.backgroundColor = [UIColor clearColor];
    tableTVShows.layer.backgroundColor = [[UIColor clearColor] CGColor];
    tableTVShows.allowsSelection = NO;
    [ContentMetaDataView addSubview:tableTVShows];
}

+ (NSInteger)numberOfSectionsInTableViewTVShows:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

+ (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == tableTVShows) {
        return actorsTVShow.count;
    } else {
        return episodesTVShow.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

+ (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *textColor = [UIColor colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0];
    static NSString *cellIdentifier = @"cellIdentifier";
    if (tableView == tableTVShows) {
        UITableViewCell *cell = [tableTVShows dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        
        NSDictionary *thisActor = [actorsTVShow objectAtIndex:indexPath.row];
        
        NSString *name = [[NSString alloc] initWithString:[thisActor objectForKey:@"name"]];
        NSString *role = [[NSString alloc] initWithString:[thisActor objectForKey:@"role"]];
        NSString *image = [[NSString alloc] initWithString:[thisActor objectForKey:@"image"]];
        
        // Set the coverflow picture for this content item
        NSURL *theURL = [NSURL URLWithString:image];
        UIImage *thisImage;
        [ImageLoader preloadImage2:image :cell];
        if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[theURL absoluteString]]) {
            thisImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[theURL absoluteString]];
        } else {
            if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:[theURL absoluteString]])
            {
                // Set cached thumbnail image on imageview
                thisImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[theURL absoluteString]];
            }
        }
        
        cell.textLabel.text = name;
        cell.detailTextLabel.text = role;
        cell.imageView.image = thisImage;
        cell.backgroundColor = [UIColor clearColor];
        cell.layer.backgroundColor = [[UIColor clearColor] CGColor];
        cell.textLabel.textColor = textColor;
        cell.detailTextLabel.textColor = textColor;
        return cell;
    } else {
        @try {
            UITableViewCell *cell = [tableContentView dequeueReusableCellWithIdentifier:cellIdentifier];

            if(cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            }
            
            // TODO: build play functions here....
            NSDictionary *thisEpisode = [episodesTVShow objectAtIndex:indexPath.row];
            NSArray *local_data = [[NSArray alloc] initWithArray:[thisEpisode valueForKeyPath:@"locale_data"]];
            NSString *season_number = @"";
            NSString *episode_number = @"";
            NSString *poster_url = @"";
            NSString *plot = @"";
            NSString *title = @"";
            
            @try {
                season_number = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", [thisEpisode valueForKeyPath:@"season_number"]]];
                episode_number = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", [thisEpisode valueForKeyPath:@"episode_number"]]];
                poster_url = [thisEpisode valueForKeyPath:@"poster_url"];
                plot = [[NSString alloc] initWithString:[local_data[0] valueForKeyPath:@"plot"]];
                title = [[NSString alloc] initWithString:[local_data[0] valueForKeyPath:@"title"]];
            }
            @catch(NSException * e) {
                NSLog(@"Exception: %@", e);
            }
            @finally {
            }
            
            // Set the coverflow picture for this content item
            UIImage *thisImage;
            if ([poster_url isKindOfClass:[NSNull class]]) {
                thisImage = [UIImage imageNamed:@"placeholderEpisode.png"];
            } else {
                NSString *image = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%@:7080/omnimage.jpg?id=%@&thumb=330x0", protocol, server, poster_url]];
                thisImage = [ImageLoader preloadImage3:image :cell];
            }
            
            // draw scaled image into thumbnail context
            UIImage *imageScale = thisImage;
            UIGraphicsBeginImageContext(CGSizeMake(300, 200));
            [imageScale drawInRect:CGRectMake(0, 0, 300, 169)]; //
            UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            if(newThumbnail == nil)
            {
                cell.imageView.image = imageScale;
            } else {
                cell.imageView.image = newThumbnail;
            }
            
            [cell setTag:indexPath.row];
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startEpisode:)];
            [cell addGestureRecognizer:tap];
            cell.layer.borderColor = [[UIColor clearColor] CGColor];
            cell.layer.borderWidth = 3;
            cell.textLabel.text = [NSString stringWithFormat:@"[S%@|E%@] %@", season_number, episode_number, title];
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
            
            cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:8];
            cell.detailTextLabel.numberOfLines = 6;
            cell.detailTextLabel.text = plot;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.backgroundColor = [UIColor clearColor];
            cell.layer.backgroundColor = [[UIColor clearColor] CGColor];
            cell.textLabel.textColor = textColor;
            cell.detailTextLabel.textColor = textColor;
            
            return cell;
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
        }
    }
}

+ (void)startEpisode:(id)sender
{
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    CGPoint point = [tap locationInView:tableContentView];
    NSIndexPath *theIndexPath = [tableContentView indexPathForRowAtPoint:point];
    NSInteger theRowIndex = theIndexPath.row;
    NSDictionary *thisEpisode = [episodesTVShow objectAtIndex:theRowIndex];
    NSString *url = [[NSString alloc] initWithString:[thisEpisode valueForKeyPath:@"url"]];
    contentURL = [NSURL URLWithString:url];
    NSDictionary *url_dict = [NSDictionary dictionaryWithObject:contentURL forKey:@"url"];
    NSLog(@"startEpisode contentURL: %@", contentURL);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startTVShow" object:nil userInfo:url_dict];
}


+ (void)SetPlotTVShows:(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat width = ContentMetaDataView.frame.size.width;
    CGFloat height = ContentMetaDataView.frame.size.height;
    
    // [[UITextView alloc] initWithFrame:CGRectMake(25 + (0.25 * width), -15 + (0.666 * height) , -25 + (0.75 * 548), 50)];
    
    Synopsis = [[UITextView alloc] initWithFrame:CGRectMake(25 + (0.25 * width), 25 + (0.666 * height), -30 + (0.75 * width), 70)];
    Synopsis.font = [UIFont fontWithName:@"Helvetica" size:12];
    
    // Kodi blue: colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0
    UIColor *textColor = [UIColor colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0];
    NSArray *plot = [MetaData[pressedIndexPath.item] valueForKeyPath:@"TVShowdetail.locale_data.plot"];
    Synopsis.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
    Synopsis.layer.masksToBounds = YES;
    Synopsis.selectable = NO;
    Synopsis.layer.borderColor = [[UIColor clearColor] CGColor];
    Synopsis.backgroundColor = [UIColor clearColor];
    Synopsis.editable = NO;
    Synopsis.alpha = 1.0f;
    Synopsis.textColor = textColor;
    Synopsis.textAlignment = NSTextAlignmentJustified;
    [Synopsis setText:[NSString stringWithFormat:@"%@", plot[0]]];
    Synopsis.tag = 70;
    [ContentMetaDataView addSubview:Synopsis];
}

+ (void)SetBackButtonTVShows
{
    // Set Back Button
    UIButton *thisbutton;
    if (ContentMetaDataView.frame.size.width == 548) {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake(ContentMetaDataView.frame.size.width - 60, 0, 50, 50)];
    } else {
        thisbutton = [[UIButton alloc] initWithFrame:CGRectMake(ContentMetaDataView.frame.size.width - 90, 0, 80, 80)];
    }
    [thisbutton addTarget:self action:@selector(DestroyContentMetaDataViewTVShows) forControlEvents:UIControlEventTouchUpInside];
    UIImage *thisButtonImage = [UIImage imageNamed:@"back3.png"];
    [thisbutton setImage:thisButtonImage forState:UIControlStateNormal];
    [ContentMetaDataView addSubview:thisbutton];
    thisbutton.tag = 70;
}

+ (void)SetImageTVShows:(CDemoCollectionViewCell*)theCell :(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath {
    CGFloat height = ContentMetaDataView.frame.size.height;
    CGFloat width = ContentMetaDataView.frame.size.width;
    
    // Set the coverflow picture for this content item
    NSString *fanart_str = [NSString stringWithFormat:@"%@%@:7080/omnimage.jpg?id=%@&thumb=500x0", protocol, server, [MetaData[pressedIndexPath.item] valueForKeyPath:@"TVShowdetail.fanart_url"]];
    NSURL *fanart_url = [NSURL URLWithString:fanart_str];
    UIImageView *fanart = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    fanart.tag = 70;
    
    [ImageLoader loadImage:fanart_str :fanart];
    if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[fanart_url absoluteString]]) {
        fanart.image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[fanart_url absoluteString]];
        
    } else {
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:[fanart_url absoluteString]])
        {
            // Set cached thumbnail image on imageview
            fanart.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[fanart_url absoluteString]];
        }
    }
    
    NSString *thumb_str = [MetaData[pressedIndexPath.item] objectForKey:@"poster"];
    NSURL *thumb_url = [NSURL URLWithString:thumb_str];
    UIImage *thumb;
    
    [ImageLoader loadImage:thumb_str :fanart];
    if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[thumb_url absoluteString]]) {
        thumb = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[thumb_url absoluteString]];
        
    } else {
        if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:[thumb_url absoluteString]])
        {
            // Set cached thumbnail image on imageview
            thumb = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[thumb_url absoluteString]];
        }
    }
    
    if (height == 675 && width == 984) {
        infoBlokBar = [[UIView alloc] initWithFrame:CGRectMake(0, 118 + height * 0.5, width, height * 0.5)];
    } else {
        infoBlokBar = [[UIView alloc] initWithFrame:CGRectMake(0, 55 + height * 0.5, width, height * 0.5)];
    }
    
    infoBlokBar.backgroundColor = [UIColor colorWithRed:30.0/255.0f green:72.0/255.0f blue:101.0/255.0f alpha:0.8];
    infoBlokBar.tag = 70;
    
    // Add button on image for switching between metadata and season/episodes list
    switcher = [[UIButton alloc] initWithFrame:CGRectMake(20, height / 4, width / 4, (width / 4) * 1.5)];
    [switcher setImage:thumb forState:UIControlStateNormal];
    switcher.layer.cornerRadius = 5;
    switcher.layer.masksToBounds = YES;
    [switcher addTarget:self action:@selector(SwitchMetaDataSeasonsAndEpisodes) forControlEvents:UIControlEventTouchUpInside];
    
    [ContentMetaDataView addSubview:fanart];
    [ContentMetaDataView addSubview:infoBlokBar];
    [ContentMetaDataView addSubview:switcher];
}

+ (void)SwitchMetaDataSeasonsAndEpisodes {
    seasonsview = !seasonsview;
    if (seasonsview) {
        // Remove all elements from superview...
        [ratingLabel removeFromSuperview];
        [durationLabel removeFromSuperview];
        [infoPane removeFromSuperview];
        [TrailerButton removeFromSuperview];
        [kodiControlButton removeFromSuperview];
        [contentTitle removeFromSuperview];
        [Synopsis removeFromSuperview];
        [infoBlokBar removeFromSuperview];
        
        // Add new subview
        [ContentMetaDataView addSubview:blurView];
        [blurView addSubview:tableContentView];
    } else {
        // Add new subview
        [ContentMetaDataView addSubview:infoPane];
        [ContentMetaDataView addSubview:ratingLabel];
        [ContentMetaDataView addSubview:durationLabel];
        [ContentMetaDataView addSubview:TrailerButton];
        [ContentMetaDataView addSubview:kodiControlButton];
        [ContentMetaDataView addSubview:infoBlokBar];
        [ContentMetaDataView addSubview:contentTitle];
        [ContentMetaDataView addSubview:Synopsis];
        [switcher removeFromSuperview ];
        [ContentMetaDataView addSubview:switcher];
        
        // remove subview
        [blurView removeFromSuperview];
        [tableContentView removeFromSuperview];
    }
}

+ (void)SetTitleTVShows:(NSMutableArray*)MetaData :(NSIndexPath*)pressedIndexPath
{
    CGFloat height = ContentMetaDataView.frame.size.height;
    CGFloat width = ContentMetaDataView.frame.size.width;
    
    contentTitle = [[UITextView alloc] initWithFrame:CGRectMake(25 + (0.25 * width), (0.666 * height), -25 + (0.75 * width), 50)];
    contentTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];

    // Kodi blue: colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0
    UIColor *TitleColor = [UIColor colorWithRed:0.34f green:0.75f blue:0.94f alpha:1.0];
    NSArray *titleArray = [MetaData[pressedIndexPath.item] valueForKeyPath:@"TVShowdetail.locale_data.title"];
    NSString *title = [NSString stringWithFormat:@"%@", titleArray[0]];
    NSString *originalTitle = [NSString stringWithFormat:@"%@", [MetaData[pressedIndexPath.item] objectForKey:@"TVShowdetail.original_title"]];
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
    [ContentMetaDataView addSubview:contentTitle];
}

+ (void)DestroyContentMetaDataViewTVShows
{
    seasonsview = false;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DestroyContentMetaDataView" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"startTVShow" object:nil];
}

@end
