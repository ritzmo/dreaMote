//
//  NSArray+ArrayFromData.h
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(ArrayFromData)

/*!
 @brief Return new array from data.

 @param data Data to use
 @return array object
 */
+ (id)arrayWithData:(NSData *)data;

/*!
 @brief Initialize with data.

 @param data Data to initialize with
 @return array object
 */
- (id)initWithData:(NSData *)data;

@end
