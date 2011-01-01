//
//  EventProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceProtocol.h"

/*!
 @brief Interface of an Event.
 */
@protocol EventProtocol

/*!
 @brief Event Id.
 */
@property (nonatomic, retain) NSString *eit;

/*!
 @brief Begin.
 */
@property (nonatomic, retain) NSDate *begin;

/*!
 @brief End.
 */
@property (nonatomic, retain) NSDate *end;

/*!
 @brief Title.
 */
@property (nonatomic, retain) NSString *title;

/*!
 @brief Short Description.
 */
@property (nonatomic, retain) NSString *sdescription;

/*!
 @brief Extended Description.
 */
@property (nonatomic, retain) NSString *edescription;

/*!
 @brief Cache for Begin/End Textual representation.
 */
@property (nonatomic, retain) NSString *timeString;

/*!
 @brief Service the Event is aired on.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;



/*!
 @brief Set Begin from Timestamp as String.

 @param newBegin String with Unix Timestamp of Begin.
 */
- (void)setBeginFromString: (NSString *)newBegin;

/*!
 @brief Set End based on a duration provided as String.
 
 @param String with Unix Timestamp of Duration.
 */
- (void)setEndFromDurationString: (NSString *)newDuration;

/*!
 @brief Check equality with another Event based on properties.

 @param otherEvent Event to check equality with.
 @return YES if equal.
 */
- (BOOL)isEqualToEvent: (NSObject<EventProtocol> *)otherEvent;

/*!
 @brief Compare to another event based on begin.
 
 @param otherEvent Event to compare to.
 @return NSOrderedAscending if otherEvent is earlier
 */
- (NSComparisonResult)compare: (NSObject<EventProtocol> *)otherEvent;

@end
