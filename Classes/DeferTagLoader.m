//
//  DeferTagLoader.m
//  dreaMote
//
//  Created by Moritz Venn on 04.12.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "DeferTagLoader.h"

#import <Connector/RemoteConnectorObject.h>

@interface DeferTagLoader()
@property (nonatomic, strong) NSMutableArray *tags;
@property (nonatomic, strong) SaxXmlReader *xmlReader;
@end

@implementation DeferTagLoader
@synthesize callback, tags, xmlReader;

- (id)init
{
	if((self = [super init]))
	{
		tags = [NSMutableArray array];
	}
	return self;
}

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	tagLoaderCallback_t call = callback;
	callback = nil;
	if(call)
		call(tags, NO);
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	tagLoaderCallback_t call = callback;
	callback = nil;
	if(call)
		call(tags, YES);
}

- (void)loadTags
{
	xmlReader = [[RemoteConnectorObject sharedRemoteConnector] fetchTags:self];
}

- (void)addTag:(Tag *)anItem
{
	if(anItem.valid)
		[tags addObject:anItem.tag];
}
@end