//
//  ServiceTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/ServiceProtocol.h"

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kServiceCell_ID;

/*!
 @brief UITableViewCell optimized to display Services.
 */
@interface ServiceTableViewCell : UITableViewCell
{
@private	
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
	UILabel *_serviceNameLabel; /*!< @brief Name Label. */
}

/*!
 @brief Name Label.
 */
@property (nonatomic, retain) UILabel *serviceNameLabel;

/*!
 @brief Service.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> * service;

@end

