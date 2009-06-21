//
//  MainTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kMainCell_ID;

/*!
 @brief UITableViewCell optimized to display Services.
 */
@interface MainTableViewCell : UITableViewCell
{
@private
	NSDictionary	*_dataDictionary; /*!< @brief Item. */
	UILabel			*_nameLabel; /*!< @brief Name Label. */
	UILabel			*_explainLabel; /*!< @brief Explanation Label. */
}

/*!
 @brief Item.
 */
@property (nonatomic, retain) NSDictionary *dataDictionary;

/*!
 @brief Name Label.
 */
@property (nonatomic, retain) UILabel *nameLabel;

/*!
 @brief Explanation Label.
 */
@property (nonatomic, retain) UILabel *explainLabel;

@end
