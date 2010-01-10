//
//  Volume.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Result.h"

/*!
 @brief Generic Volume.
 */
@interface GenericVolume : Result
{
@private
	NSInteger _current; /*!< @brief Current audio level. */
	BOOL _ismuted; /*!< @brief Audio currently muted? */
}

/*!
 @brief Current audio level.
 */
@property (assign) NSInteger current;

/*!
 @brief Audio currently muted?
 */
@property (assign) BOOL ismuted;

@end
