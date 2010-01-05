//
//  Volume.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "Volume.h"

@implementation GenericVolume

@synthesize result = _result;
@synthesize resulttext = _resulttext;
@synthesize current = _current;
@synthesize ismuted = _ismuted;

- (void)dealloc
{
	[_resulttext release];

	[super dealloc];
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> ResultText: '%@'.\nCurrent: '%i'.\nIs muted: '%d'.\n", [self class], self.resulttext, self.current, self.ismuted];
}

- (void)setResultFromString: (NSString *)newResult
{
	_result = [newResult isEqualToString: @"True"];
}

- (void)setCurrentFromString: (NSString *)newCurrent
{
	_current = [newCurrent integerValue];
}

- (void)setIsmutedFromString: (NSString *)newMuted
{
	_ismuted = [newMuted isEqualToString: @"True"];
}

@end
