//
//  Signal.h
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Signal : NSObject
{
@private
	float snrdb;
	NSInteger snr;
	NSInteger ber;
	NSInteger agc;
}

@property (assign) float snrdb;
@property (assign) NSInteger snr;
@property (assign) NSInteger ber;
@property (assign) NSInteger agc;

@end
