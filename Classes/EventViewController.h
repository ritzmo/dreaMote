//
//  EventViewController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Event.h"
#import "Service.h"

@interface EventViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate,
													UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource>
{
	Event *_event;
	Service *_service;
	UITableView	*myTableView;
}

+ (EventViewController *)withEvent: (Event *) newEvent;
+ (EventViewController *)withEventAndService: (Event *) newEvent: (Service *)newService;

@property (nonatomic, retain) Event *event;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) UITableView *myTableView;

@end
