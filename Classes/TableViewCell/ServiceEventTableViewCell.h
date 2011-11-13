//
//  ServiceEventTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/FastTableViewCell.h>

#import <Objects/EventProtocol.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kServiceEventCell_ID;

/*!
 @brief UITableViewCell optimized to display Service/Now/Next combination.
 */
@interface ServiceEventTableViewCell : FastTableViewCell
{
@private
	NSInteger timeWidth; /*!< @brief Width reserved for time. */
}

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *formatter;

/*!
 @brief Current Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *now;

/*!
 @brief Next Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *next;

@end

