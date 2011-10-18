//
//  Package.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "Package.h"

@implementation Package
@synthesize name, version, upgradeVersion, installed;

+ (Package *)packageFromString:(NSString *)packageString withInstalledState:(installedState)state
{
	NSArray *components = [packageString componentsSeparatedByString:@" - "];
	if(components.count < 2)
	{
#if IS_DEBUG()
		NSLog(@"tried to generate package from invalid string: %@", packageString);
#endif
		return nil;
	}

	Package *pkg = [[Package alloc] init];
	pkg.name = [components objectAtIndex:0];
	pkg.version = [components objectAtIndex:1];
	if(components.count > 2)
		pkg.upgradeVersion = [[components objectAtIndex:2] stringByReplacingOccurrencesOfString:@"<br>" withString:@""];
	else
		pkg.version = [pkg.version stringByReplacingOccurrencesOfString:@"<br>" withString:@""];
	pkg.installed = state;

	return [pkg autorelease];
}

@end
