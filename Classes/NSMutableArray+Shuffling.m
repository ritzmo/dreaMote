//
//  NSMutableArray+Shuffling.m
//  dreaMote
//
//  Created by Moritz Venn on 11.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "NSMutableArray+Shuffling.h"

@implementation NSMutableArray(Shuffling)

- (void)shuffle
{
	static BOOL hasSeeded = NO;
	if(!hasSeeded)
	{
		hasSeeded = YES;
		srandom(time(NULL));
	}

	const NSUInteger count = [self count];
	NSUInteger i = 0;
	for(; i < count; ++i)
	{
		NSUInteger nElements = count - i;
		NSUInteger n = (random() % nElements) + i;
		[self exchangeObjectAtIndex:i withObjectAtIndex:n];
	}
}

@end
