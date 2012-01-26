//
//  Volume.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "Volume.h"

@implementation GenericVolume

@synthesize current, ismuted;

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> ResultText: '%@'.\nCurrent: '%i'.\nIs muted: '%d'.\n", [self class], self.resulttext, self.current, self.ismuted];
}

- (void)setCurrentFromString: (NSString *)newCurrent
{
	self.current = [newCurrent integerValue];
}

- (void)setIsmutedFromString: (NSString *)newMuted
{
	self.ismuted = [newMuted isEqualToString:@"True"];
}

@end
