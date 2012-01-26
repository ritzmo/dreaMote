//
//  UIDevice+SystemVersion.h
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIDevice(SystemVersion)

/*!
 @brief Check current iOS version against given one.

 @param version float value of lowest version to check for
 @return YES if iOS version >= input value, else NO.
 */
+ (BOOL)newerThanIos:(float)version;

/*!
 @brief Check current iOS version against given one.

 @param version float value of highest version to check for
 @return YES if iOS version < input value, else NO.
 */
+ (BOOL)olderThanIos:(float)version;

@end
