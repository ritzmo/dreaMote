//
//  Volume.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Volume.h"

@implementation GenericVolume

@synthesize current = _current;
@synthesize ismuted = _ismuted;

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> ResultText: '%@'.\nCurrent: '%i'.\nIs muted: '%d'.\n", [self class], self.resulttext, self.current, self.ismuted];
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
