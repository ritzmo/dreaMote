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
	Package *pkg = [[Package alloc] init];
	NSArray *components = [packageString componentsSeparatedByString:@" - "];
	pkg.name = [components objectAtIndex:0];
	pkg.version = [components objectAtIndex:1];
	if(components.count > 2)
		pkg.upgradeVersion = [components objectAtIndex:2];
	pkg.installed = state;

	return [pkg autorelease];
}

@end
