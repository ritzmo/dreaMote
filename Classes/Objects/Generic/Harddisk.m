//
//  Harddisk.m
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Harddisk.h"

@implementation Harddisk

@synthesize capacity, free, model;

- (id)initWithModel:(NSString *)newModel andCapacity:(NSString *)newCapacity andFree:(NSString *)newFree
{
	if((self = [super init]))
	{
		self.model = newModel;
		self.capacity = newCapacity;
		self.free = newFree;
	}
	return self;
}

@end
