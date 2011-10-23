//
//  UIDevice+SystemVersion.m
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "UIDevice+SystemVersion.h"


@implementation UIDevice(SystemVersion)

+ (BOOL)newerThanIos:(float)version
{
	float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	return (currentVersion >= version);
}

+ (BOOL)olderThanIos:(float)version
{
	float currentVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
	return (currentVersion < version);
}

@end
