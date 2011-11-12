//
//  ServiceTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TableViewCell/BaseTableViewCell.h>

#import <Objects/ServiceProtocol.h>

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kServiceCell_ID;

/*!
 @brief UITableViewCell optimized to display Services.
 */
@interface ServiceTableViewCell : BaseTableViewCell

/*!
 @brief Enable/Disable use of picon rounding.
 @param roundedPicons Use rounded picons?
 */
- (void)setRoundedPicons:(BOOL)roundedPicons;

/*!
 @brief Font to be used for drawing.
 */
@property (nonatomic, strong) UIFont *font;

/*!
 @brief Service.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> *service;

@end

