//
//  MetaDataView.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 15/04/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//
#import "CDemoCollectionViewCell.h"

@interface MetaDataViewTVShows : CDemoCollectionViewCell
+ (void)ContentMetaDataViewTVShows:(UIView*)view :(CDemoCollectionViewCell*)theCell :(NSIndexPath *)pressedIndexPath :(NSIndexPath *)theIndexPath :(NSMutableArray*)MetaDataTVShow :(NSString*)hostname :(bool)protocol :(NSURL*)currentTVShowURL;
@end
