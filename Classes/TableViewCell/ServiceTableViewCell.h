//
//  ServiceTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
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
	BOOL _loadPicon; /*!< @brief Load Picons internally. */
}

/*!
 @brief Name Label.
 */
@property (nonatomic, strong) UILabel *serviceNameLabel;

/*!
 @brief Service.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> * service;

/*!
 @brief Load Picons internally?
 When showing a large ammount of services (e.g. in the Service List) loading the picons can make
 the UI respond slowly to user interaction. By factoring out the loading code into a background
 thread the parent view can control this.
 */
@property (nonatomic, assign) BOOL loadPicon;

@end

