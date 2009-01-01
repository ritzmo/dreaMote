//
//  EventViewController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"
#import "Objects/ServiceProtocol.h"

@interface EventViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSObject<EventProtocol> *_event;
	NSObject<ServiceProtocol> *_service;
}

+ (EventViewController *)withEventAndService: (NSObject<EventProtocol> *) newEvent: (NSObject<ServiceProtocol> *)newService;

@property (nonatomic, retain) NSObject<EventProtocol> *event;
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

@end
