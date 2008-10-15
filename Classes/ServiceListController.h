//
//  ServiceListController.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceListController : UIViewController <UIActionSheetDelegate,
													UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_services;
	SEL _selectCallback;
	id _selectTarget;
	BOOL _refreshServices;
}

- (void)setTarget: (id)target action: (SEL)action;

@end
