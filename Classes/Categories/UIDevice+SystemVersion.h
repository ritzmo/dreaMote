//
//  UIDevice+SystemVersion.h
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Does the current device run on iOS 4.0 or better?

 @return YES if systemVersion >= 4.0, else NO.
 */
#define runsIos4OrBetter	newerThanIos:4.0f

/*!
 @brief Does the current device run on iOS 4.2 or better?

 @return YES if systemVersion >= 4.2, else NO.
 */
#define runsIos42OrBetter	newerThanIos:4.2f

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
