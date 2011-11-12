//
//  EventTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/BaseTableViewCell.h>

#import <View/EventCellContentView.h>
#import <Objects/EventProtocol.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kEventCell_ID;

/*!
 @brief UITableViewCell optimized to display Events.
 */
@interface EventTableViewCell : BaseTableViewCell

/*!
 @brief View doing the actual work.
 */
@property (nonatomic, strong) EventCellContentView *cellView;

@end
