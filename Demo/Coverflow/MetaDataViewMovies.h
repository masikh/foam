//
//  MetaDataView.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 15/04/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//
#import "CDemoCollectionViewCell.h"

@interface MetaDataViewMovies : CDemoCollectionViewCell
+ (void)ContentMetaDataViewMovies:(UIView*)view :(CDemoCollectionViewCell*)theCell :(NSIndexPath *)pressedIndexPath :(NSIndexPath *)theIndexPath :(NSMutableArray*)MetaData;
@end
