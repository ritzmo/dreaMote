//
//  NSData+Base64.h
//  base64
//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Foundation/Foundation.h>

@interface NSData (Base64)

/*!
 @brief Returns data from base64 encoded string.
 Creates an NSData object containing the base64 decoded representation of
 the base64 string 'aString'

 @param aString the base64 string to decode
 @return the autoreleased NSData representation of the base64 string
 */
+ (NSData *)dataFromBase64String:(NSString *)aString;

/*!
 @brief Returns base64 encoded string.
 Creates an NSString object that contains the base 64 encoding of the
 receiver's data. Lines are broken at 64 characters long.

 @return an autoreleased NSString being the base 64 representation of the receiver.
 */
- (NSString *)base64EncodedString;

@end
