//
//  ServiceEventTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/BaseTableViewCell.h>

#import <View/ServiceEventCellContentView.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kServiceEventCell_ID;

/*!
 @brief UITableViewCell optimized to display Service/Now/Next combination.
 */
@interface ServiceEventTableViewCell : BaseTableViewCell

/*!
 @brief Custom rendering view.
 */
@property (nonatomic, strong) ServiceEventCellContentView *cellView;

@end

