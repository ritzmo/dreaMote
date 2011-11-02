//
//  Harddisk.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Harddisk : NSObject

- (id)initWithModel:(NSString *)model andCapacity:(NSString *)capacity andFree:(NSString *)free;

/*!
 @brief Capacity.
 */
@property (nonatomic, strong) NSString *capacity;

/*!
 @brief Free space.
 */
@property (nonatomic, strong) NSString *free;

/*!
 @brief Drive Model.
 */
@property (nonatomic, strong) NSString *model;

@end
