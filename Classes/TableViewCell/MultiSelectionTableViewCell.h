//
//  MultiSelectionTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 15.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <TableViewCell/FastTableViewCell.h>

@interface MultiSelectionTableViewCell : FastTableViewCell
{
@private
	UIImage *indicatorImage; /*!< @brief Indicator Image. */
	BOOL _multiSelected;
}

/*!
 @brief Set selection in Multi-Select mode.

 @param selected If the cell should be selected.
 @param animated Animate (de)selection?
 */
- (void)setMultiSelected:(BOOL)selected animated:(BOOL)animated;

/*!
 @brief Toggle selection in Multi-Select mode.

 @return selection status after running this method
 */
- (BOOL)toggleMultiSelected;

@end
