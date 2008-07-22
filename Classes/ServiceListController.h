//
//  ServiceListController.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceListController : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSMutableArray *_services;
	SEL _selectCallback;
	id _selectTarget;
	int _serviceCount;
	BOOL _refreshServices;
}

- (void)reloadData;
- (void)setTarget: (id)target action: (SEL)action;

@property (nonatomic, retain) NSMutableArray *services;
@property (nonatomic) SEL selectCallback;
@property (nonatomic, retain) id selectTarget;
@property (nonatomic) int serviceCount;
@property (nonatomic) BOOL refreshServices;

@end
