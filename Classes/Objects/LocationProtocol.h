//
//  LocationProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Interface of a Location.
 */
@protocol LocationProtocol

/*!
 @brief Full path
 */
@property (nonatomic, retain) NSString *fullpath;

/*!
 @brief Valid or Fake Location.
 */
@property (nonatomic, assign) BOOL valid;

@end
