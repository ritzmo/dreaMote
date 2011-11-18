//
//  DreamoteSHKConfigurator.m
//  dreaMote
//
//  Created by Moritz Venn on 16.10.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "DreamoteSHKConfigurator.h"

@implementation DreamoteSHKConfigurator

- (NSString*)appName {
	return @"dreaMote";
}

- (NSString*)appURL {
	return @"https://freaque.net/dreaMote";
}

- (NSString*)twitterUsername {
	return @"dreaMote";
}

- (NSNumber*)maxFavCount {
	return [NSNumber numberWithInt:IS_IPAD() ? 4 : 3];
}

@end