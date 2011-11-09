//
//  BaseTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kBaseCell_ID;

@interface BaseTableViewCell : UITableViewCell

/*!
 @brief Apply theme.
 */
- (void)theme;

@end
