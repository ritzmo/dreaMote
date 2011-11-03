//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Objects/EventProtocol.h>

/*!
 @brief Generic Event.
 */
@interface GenericEvent : NSObject <EventProtocol>
{
@private
	NSTimeInterval _duration; /*!< @brief Duration. */
}

/*!
 @brief Init with existing Event.

 @note Required to create a Copy.
 @param event Event to copy.
 @return Event instance.
 */
- (id)initWithEvent:(NSObject<EventProtocol> *)event;

@end
