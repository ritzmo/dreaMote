//
//  NSDictionary+DictionaryFromData.m
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "NSDictionary+DictionaryFromData.h"

@implementation NSDictionary(DictionaryFromData)

+ (id)dictionaryWithData:(NSData *)data
{
	return [[[NSDictionary alloc] initWithData:data] autorelease];
}

- (id)initWithData:(NSData *)data
{
	NSPropertyListSerialization *plist = nil;
	float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	if(currentVersion >= 4.0)
	{
		plist = [NSPropertyListSerialization propertyListWithData:data
														  options:NSPropertyListImmutable
														   format:nil
															error:nil];
	}
	else
	{
		plist = [NSPropertyListSerialization propertyListFromData:data
												 mutabilityOption:NSPropertyListImmutable
														   format:nil
												 errorDescription:nil];
	}
	return [self initWithDictionary:(NSDictionary *)plist];
}

@end
