//
//  CircularNSMutableArray.h
//  Omniyon-ATV3
//
//  Created by Robert Nagtegaal on 11/01/16.
//  Copyright © 2016 toxicsoftware. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CircularQueue : NSObject <NSFastEnumeration>

@property (nonatomic, assign, readonly) NSUInteger capacity;
@property (nonatomic, assign, readonly) NSUInteger count;

- (id)initWithCapacity:(NSUInteger)capacity;

- (void)enqObject:(id)obj; // Enqueue
- (id)deqObject;           // Dequeue

- (id)objectAtIndex:(NSUInteger)index;
- (void)removeAllObjects;

@end
