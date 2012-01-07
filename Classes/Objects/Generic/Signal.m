//
//  Signal.m
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "Signal.h"

@implementation GenericSignal

@synthesize snrdb, snr, ber, agc;

- (id)init
{
	if((self = [super init]))
	{
		snrdb = NSNotFound;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> SNRdB: '%f dB'.\nSNR: '%i %'.\nBER: '%i'.\nAGC: '%i %'.\n", [self class], self.snrdb, self.snr, self.ber, self.agc];
}

@end
