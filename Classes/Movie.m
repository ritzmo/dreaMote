//
//  Movie.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Movie.h"

@implementation Movie

@synthesize sref = _sref;
@synthesize sname = _sname;
@synthesize time = _time;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;
@synthesize length = _length;
@synthesize size = _size;
@synthesize tags = _tags;

- (void)setTimeFromString: (NSString *)newTime
{
	[_time release];
	_time = [[NSDate dateWithTimeIntervalSince1970: [newTime doubleValue]] retain];
}

- (void)setTagsFromString: (NSString *)newTags
{
	[_tags release];
	_tags = [newTags componentsSeparatedByString:@" "];
}

@end
