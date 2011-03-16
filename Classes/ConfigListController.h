//
//  ConfigListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#if IS_FULL()
	#import "MultiEPGIntervalViewController.h"
#endif

/*!
 @brief General settings and connection list.
 
 Allows to set Application preferences and Add/Remove of known Connections.
 */
@interface ConfigListController : UIViewController <UITableViewDelegate,
#if IS_FULL()
													MultiEPGIntervalDelegate,
#endif
													UITableViewDataSource>
{
@private
	NSMutableArray *_connections; /*!< @brief List of Connections. */
	UISwitch *_vibrateInRC; /*!< @brief "Vibrate in RC" UISwitch. */
	UISwitch *_simpleRemote; /*!< @brief "Use simple remote" UISwitch. */
}

@end
