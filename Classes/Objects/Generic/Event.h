//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EventProtocol.h"

/*!
 @brief Generic Event.
 */
@interface GenericEvent : NSObject <EventProtocol>
{
@private	
	NSString *_eit; /*!< @brief Event Id. */
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */
	NSString *_title; /*!< @brief Title. */
	NSString *_sdescription; /*!< @brief Short Description. */
	NSString *_edescription; /*!< @brief Extended Description. */
	double _duration; /*!< @brief Duration. */

	NSString *_timeString; /*!< @brief Cache for Begin/End Textual representation. */
}

/*!
 @brief Init with existing Event.

 @note Required to create a Copy.
 @param event Event to copy.
 @return Event instance.
 */
- (id)initWithEvent:(NSObject<EventProtocol> *)event;

@end
