//
//  ServiceTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Service.h"

@interface ServiceTableViewCell : UITableViewCell {

@private	
	Service *_service;
}

@property (nonatomic, retain) Service *service;

@end

