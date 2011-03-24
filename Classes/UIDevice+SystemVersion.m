//
//  UIDevice+SystemVersion.m
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "UIDevice+SystemVersion.h"


@implementation UIDevice(SystemVersion)

+ (BOOL)runsIos4OrBetter
{
	float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	return (currentVersion >= 4.0f);
}

+ (BOOL)runsIos42OrBetter
{
	float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	return (currentVersion >= 4.2f);
}

@end
