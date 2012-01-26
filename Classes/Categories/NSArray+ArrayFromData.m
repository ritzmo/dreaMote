//
//  NSArray+ArrayFromData.m
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "NSArray+ArrayFromData.h"

@implementation NSArray(ArrayFromData)

+ (id)arrayWithData:(NSData *)data
{
	return [[NSArray alloc] initWithData:data];
}

- (id)initWithData:(NSData *)data
{
	NSPropertyListSerialization *plist = [NSPropertyListSerialization propertyListWithData:data
																				   options:NSPropertyListImmutable
																					format:nil
																					 error:nil];
	return [self initWithArray:(NSArray *)plist];
}

@end
