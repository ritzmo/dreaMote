//
//  ServiceTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/Generic/Service.h"

// cell identifier for this custom cell
extern NSString *kServiceCell_ID;

@interface ServiceTableViewCell : UITableViewCell
{
@private	
	Service *_service;
	UILabel *_serviceNameLabel;
}

@property (nonatomic, retain) UILabel *serviceNameLabel;

- (Service*)service;
- (void)setService:(Service *)newService;

@end

