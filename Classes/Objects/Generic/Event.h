//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EventProtocol.h"

/*!
 @brief Generic Event.
 */
@interface Event : NSObject <EventProtocol>
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

@end
