//
//  MultiEPGTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/BaseTableViewCell.h>

#import <View/MultiEPGCellContentView.h>

#import <Objects/ServiceProtocol.h>
#import <Objects/EventProtocol.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kMultiEPGCell_ID;

/*!
 @brief UITableViewCell optimized to display vertical 1-Service/x-Events combination.
 */
@interface MultiEPGTableViewCell : BaseTableViewCell
{
@private
	MultiEPGCellContentView *_epgView; /*!< @brief Class dedicated to managing the cell contents. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
}

/*!
 @brief Retrieve event at a given point.
 
 @param point Position of touch.
 @return Event at point or nil if invalid.
 */
- (NSObject<EventProtocol> *)eventAtPoint:(CGPoint)point;

/*!
 @brief Service.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> *service;

/*!
 @brief View doing the actual work.
 */
@property (nonatomic, strong) MultiEPGCellContentView *epgView;

@end