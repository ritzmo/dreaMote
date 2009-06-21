//
//  Signal.m
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Signal.h"

@implementation Signal

@synthesize snrdb = _snrdb;
@synthesize snr = _snr;
@synthesize ber = _ber;
@synthesize agc = _agc;

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> SNRdB: '%f dB'.\nSNR: '%i %'.\nBER: '%i'.\nAGC: '%i %'.\n", [self class], self.snrdb, self.snr, self.ber, self.agc];
}

@end
