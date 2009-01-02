//
//  ConfigListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfigListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_connections;
	UISwitch *vibrateInRC;
	UISwitch *connectionTest;
	BOOL _shouldSave;
	BOOL _viewWillReapper;
}

@end
