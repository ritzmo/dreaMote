//
//  Result.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.10.
//  Copyright 2010-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Result : NSObject

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
@property (nonatomic, strong) NSString *resulttext;

@end
