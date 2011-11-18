//
//  DreamoteSHKConfigurator.m
//  dreaMote
//
//  Created by Moritz Venn on 16.10.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "DreamoteSHKConfigurator.h"
#import <Configuration/DreamoteConfiguration.h>

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

- (NSString*)barStyle {
	switch([DreamoteConfiguration singleton].currentTheme)
	{
		default:
			return @"UIBarStyleDefault";
		case THEME_NIGHT:
			return @"UIBarStyleBlack";
	}
}

- (UIColor *)barTintForView:(UIViewController *)vc
{
	switch([DreamoteConfiguration singleton].currentTheme)
	{
		default:
			return nil;
		case THEME_BLUE:
			return [UIColor colorWithRed:0.1 green:0.15 blue:0.55 alpha:1];
		case THEME_DARK:
			return [UIColor colorWithRed:.17 green:.17 blue:.17 alpha:1];
	} 
}

- (NSNumber*)formBgColorRed {
	// NOTE: unable to implement this unless iOS 5 and then it's still overly complicated - this API sucks :D
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)maxFavCount {
	return [NSNumber numberWithInt:IS_IPAD() ? 4 : 3];
}

@end