//
//  Movie.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Movie.h"

@implementation GenericMovie

@synthesize sref = _sref;
@synthesize sname = _sname;
@synthesize time = _time;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;
@synthesize length = _length;
@synthesize filename = _name;
@synthesize size = _size;
@synthesize tags = _tags;

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
	return _sref != nil;
}

- (NSComparisonResult)timeCompare:(NSObject<MovieProtocol> *)otherMovie
{
	NSComparisonResult res = [otherMovie.time compare:_time];
	if(res == NSOrderedSame)
	{
		res = [_title caseInsensitiveCompare:otherMovie.title];
	}
	return res;
}

- (NSComparisonResult)titleCompare:(NSObject<MovieProtocol> *)otherMovie
{
	NSComparisonResult res = [_title caseInsensitiveCompare:otherMovie.title];
	if(res == NSOrderedSame)
	{
		res = [_time compare:otherMovie.time];
	}
	return res;
}

- (void)setTimeFromString: (NSString *)newTime
{
	_time = [NSDate dateWithTimeIntervalSince1970: [newTime doubleValue]];
}

- (void)setTagsFromString: (NSString *)newTags
{
	if([newTags isEqualToString: @""])
		_tags = [NSArray array];
	else
		_tags = [newTags componentsSeparatedByString:@" "];
}

@end
