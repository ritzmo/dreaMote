//
//  Result.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.10.
//  Copyright 2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Result : NSObject {
@private
	BOOL _result; /*!< @brief Did the request succeed? */
	NSString *_resulttext; /*!< @brief Textual representation or explanation of result. */
}

/*!
 @brief Create a new result instance.
 */
+(Result *)createResult;

/*!
 @brief YES if request succeeded.
 */
@property (assign) BOOL result;

/*!
 @brief Textual representation or explanation of result.
 */
@property (nonatomic, retain) NSString *resulttext;

@end
