//
//  EventListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Service.h";

@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
@private
	NSArray *_events;
	Service *_service;
}

+ (EventListController*)withEventList: (NSArray*) eventList;
+ (EventListController*)withEventListAndService: (NSArray *) eventList: (Service *)ourService;
- (void)reloadData;

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, retain) Service *service;

@end
