//
//  ServiceTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/ServiceProtocol.h"

// cell identifier for this custom cell
extern NSString *kServiceCell_ID;

@interface ServiceTableViewCell : UITableViewCell
{
@private	
	NSObject<ServiceProtocol> *_service;
	UILabel *_serviceNameLabel;
}

@property (nonatomic, retain) UILabel *serviceNameLabel;

- (NSObject<ServiceProtocol> *)service;
- (void)setService:(NSObject<ServiceProtocol> *)newService;

@end

