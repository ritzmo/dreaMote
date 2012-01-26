//
//  Movie.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "Movie.h"

@implementation GenericMovie

@synthesize sref, sname, time, timeString, title, sdescription, edescription, length, filename, size, tags;

- (id)init
{
	if((self = [super init]))
	{
		NSNumber *invalidNumber = [NSNumber numberWithInteger: -1];
		self.length = invalidNumber;
		self.size = invalidNumber;
		self.time = nil;
		NSString *localizedNa = NSLocalizedString(@"N/A", @"");
		self.sdescription = localizedNa;
		self.edescription = localizedNa;
		self.tags = [NSArray array];
	}
	return self;
}

- (BOOL)isValid
{
	return sref != nil;
}

- (NSComparisonResult)timeCompare:(NSObject<MovieProtocol> *)otherMovie
{
	NSComparisonResult res = [otherMovie.time compare:self.time];
	if(res == NSOrderedSame)
	{
		res = [self.title caseInsensitiveCompare:otherMovie.title];
	}
	return res;
}

- (NSComparisonResult)titleCompare:(NSObject<MovieProtocol> *)otherMovie
{
	NSComparisonResult res = [title caseInsensitiveCompare:otherMovie.title];
	if(res == NSOrderedSame)
	{
		res = [self.time compare:otherMovie.time];
	}
	return res;
}

- (void)setTimeFromString: (NSString *)newTime
{
	self.time = [NSDate dateWithTimeIntervalSince1970:[newTime doubleValue]];
}

- (void)setTagsFromString: (NSString *)newTags
{
	if([newTags isEqualToString: @""])
		self.tags = [NSArray array];
	else
		self.tags = [newTags componentsSeparatedByString:@" "];
}

@end
