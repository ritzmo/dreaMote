//
//  Harddisk.m
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Harddisk.h"

@implementation Harddisk

@synthesize capacity = _capacity;
@synthesize free = _free;
@synthesize model = _model;

- (id)initWithModel:(NSString *)model andCapacity:(NSString *)capacity andFree:(NSString *)free
{
	if((self = [super init]))
	{
		_model = model;
		_capacity = capacity;
		_free = free;
	}
	return self;
}

@end
