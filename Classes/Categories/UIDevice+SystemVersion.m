//
//  UIDevice+SystemVersion.m
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "UIDevice+SystemVersion.h"


@implementation UIDevice(SystemVersion)

+ (BOOL)newerThanIos:(float)version
{
	static float currentVersion;
	if(!currentVersion)
		currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	return (currentVersion >= version);
}

+ (BOOL)olderThanIos:(float)version
{
	return ![self newerThanIos:version];
}

@end
