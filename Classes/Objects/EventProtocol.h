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
@property (nonatomic, strong) NSString *eit;

/*!
 @brief Begin.
 */
@property (nonatomic, strong) NSDate *begin;

/*!
 @brief End.
 */
@property (nonatomic, retain) NSDate *end;

/*!
 @brief Title.
 */
@property (nonatomic, strong) NSString *title;

/*!
 @brief Short Description.
 */
@property (nonatomic, strong) NSString *sdescription;

/*!
 @brief Extended Description.
 */
@property (nonatomic, strong) NSString *edescription;

/*!
 @brief Cache for Begin/End Textual representation.
 */
@property (nonatomic, strong) NSString *timeString;

/*!
 @brief Service the Event is aired on.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> *service;

/*!
 @brief Valid or Fake Service.
 */
@property (nonatomic, readonly, getter = isValid) BOOL valid;



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
