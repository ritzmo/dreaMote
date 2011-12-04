//
//  DeferTagLoader.h
//  dreaMote
//
//  Created by Moritz Venn on 04.12.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Delegates/TagSourceDelegate.h>

typedef void (^tagLoaderCallback_t)(NSArray *tags, BOOL success);

@interface DeferTagLoader : NSObject<TagSourceDelegate>

- (void)loadTags;

@property (nonatomic, copy) tagLoaderCallback_t callback;
@end
