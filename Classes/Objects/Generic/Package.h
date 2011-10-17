//
//  Package.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	STATE_UNKNOWN,
	INSTALLED,
	NOT_INSTALLED,
} installedState;

@interface Package : NSObject
{
@private
	NSString *name;
	NSString *version;
	NSString *upgradeVersion;
	installedState installed;
}

/*!
 @brief Generate a new package from given string.
 @param packageString
 @param state
 @return
 */
+ (Package *)packageFromString:(NSString *)packageString withInstalledState:(installedState)state;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *upgradeVersion;
@property (nonatomic, assign) installedState installed;

@end
