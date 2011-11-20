//
//  Tag.h
//  dreaMote
//
//  Created by Moritz Venn on 20.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tag : NSObject

/*!
 @brief Actual Tag
 */
@property (nonatomic, strong) NSString *tag;

/*!
 @brief Valid or Fake Tag.
 */
@property (nonatomic, assign) BOOL valid;

@end
