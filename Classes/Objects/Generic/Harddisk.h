//
//  Harddisk.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Harddisk : NSObject
{
@private
	NSString *_capacity; /*!< @brief Capacity. */
	NSString *_free; /*!< @brief Free Space. */
	NSString *_model; /*!< @brief Model. */
}

- (id)initWithModel:(NSString *)model andCapacity:(NSString *)capacity andFree:(NSString *)free;

@property (nonatomic, retain) NSString *capacity;
@property (nonatomic, retain) NSString *free;
@property (nonatomic, retain) NSString *model;

@end
