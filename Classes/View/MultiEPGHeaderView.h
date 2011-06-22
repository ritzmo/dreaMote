//
//  MultiEPGHeaderView.h
//  dreaMote
//
//  Created by Moritz Venn on 10.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Header view for MultiEPG displaying time
 */
@interface MultiEPGHeaderView : UIView
{
@private
	NSDate *begin; /*!< @brief Begin of currently displayed timeframe. */
	UILabel *firstTime; /*!< @brief First label with time. */
	UILabel *secondTime; /*!< @brief Second label with time. */
	UILabel *thirdTime; /*!< @brief Third label with time. */
	UILabel *fourthTime; /*!< @brief Fourth label with time. */
}

/*!
 @brief Begin of current timeframe.
 */
@property (nonatomic, retain) NSDate *begin;

@end