//
//  SleepTimer.m
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SleepTimer.h"

@implementation SleepTimer

@synthesize action, enabled, text, time, valid;

- (id)init
{
	if((self = [super init]))
	{
		valid = YES;
	}
	return self;
}

@end
