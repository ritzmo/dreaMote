//
//  UIDevice+SystemVersion.h
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIDevice(SystemVersion)

/*!
 @brief Does the current device run on iOS 4.0 or better?

 @return YES if systemVersion >= 4.0, else NO.
 */
+ (BOOL)runsIos4OrBetter;

/*!
 @brief Does the current device run on iOS 4.2 or better?

 @return YES if systemVersion >= 4.2, else NO.
 */
+ (BOOL)runsIos42OrBetter;

@end
