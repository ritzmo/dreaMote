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

- (void)dealloc
{
	[_sref release];
	[_sname release];
	[_time release];
	[_title release];
	[_sdescription release];
	[_edescription release];
	[_length release];
	[_size release];
	[_tags release];

	[super dealloc];
}

- (BOOL)isValid
{
	return _sref != nil;
}

- (void)setTimeFromString: (NSString *)newTime
{
	[_time release];
	_time = [[NSDate dateWithTimeIntervalSince1970: [newTime doubleValue]] retain];
}

- (void)setTagsFromString: (NSString *)newTags
{
	[_tags release];
	if([newTags isEqualToString: @""])
		_tags = [[NSArray array] retain];
	else
		_tags = [[newTags componentsSeparatedByString:@" "] retain];
}

@end
