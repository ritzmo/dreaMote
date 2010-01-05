//
//  RCButton.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "RCButton.h"

@implementation RCButton

@synthesize rcCode;

/* Initialize */
- (id)initWithFrame:(CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		rcCode = -1;
	}
	return self;
}

@end
