//
//  Volume.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Generic Volume.
 */
@interface GenericVolume : NSObject
{
@private
	BOOL _result; /*!< @brief Did the request succeed? */
	NSString *_resulttext; /*!< @brief Textual representation or explanation of result. */
	NSInteger _current; /*!< @brief Current audio level. */
	BOOL _ismuted; /*!< @brief Audio currently muted? */
}

/*!
 @brief YES if request succeeded.
 */
@property (assign) BOOL result;

/*!
 @brief Textual representation or explanation of result.
 */
@property (nonatomic, retain) NSString *resulttext;

/*!
 @brief Current audio level.
 */
@property (assign) NSInteger current;

/*!
 @brief Audio currently muted?
 */
@property (assign) BOOL ismuted;

@end
