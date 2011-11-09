//
//  PackageCell.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/BaseTableViewCell.h>

#import <Objects/Generic/Package.h>

// cell identifier for this custom cell
extern NSString *kPackageCell_ID;

@interface PackageCell : BaseTableViewCell
{
@private
	UIImageView *indicator; /*!< @brief Indicator Image. */
	UILabel *versionLabel;
	UILabel *availableLabel;
	Package *package;
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

@property (nonatomic, strong) Package *package;

@end