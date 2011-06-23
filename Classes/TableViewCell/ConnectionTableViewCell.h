//
//  ConnectionTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 23.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kConnectionCell_ID;

/*!
 @brief UITableViewCell optimized to display possible connections.
 */
@interface ConnectionTableViewCell : UITableViewCell
{
@private
	NSDictionary	*_dataDictionary; /*!< @brief Item. */
	UILabel			*_descriptionLabel; /*!< @brief Username/Password/Encryption. */
	UILabel			*_statusLabel; /*!< @brief Status Label. */
}

/*!
 @brief Item.
 */
@property (nonatomic, retain) NSDictionary *dataDictionary;

@end
