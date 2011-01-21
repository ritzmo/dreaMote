//
//  NSDictionary+DictionaryFromData.h
//  dreaMote
//
//  Created by Moritz Venn on 21.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary(DictionaryFromData)

/*!
 @brief Return new dictionary from data.

 @param data Data to use
 @return dictionary object
 */
+ (id)dictionaryWithData:(NSData *)data;

/*!
 @brief Initialize with data.

 @param data Data to initialize with
 @return dictionary object
 */
- (id)initWithData:(NSData *)data; 

@end
