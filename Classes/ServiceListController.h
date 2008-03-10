//
//  ServiceListController.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceListController : UIViewController <UIModalViewDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSArray *_services;
}

- (void)reloadData;

@property (nonatomic, retain) NSArray *services;

@end