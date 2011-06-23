//
//  ConnectionListController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ConfigViewController.h"

/*!
 @brief Connection List used in AutoConfiguration.
 
 Displays a given list of possible connections.
 */
@interface ConnectionListController : UIViewController <UITableViewDelegate,
														UITableViewDataSource>
{
@private
	NSArray *_connections; /*!< @brief List of found connections. */
	ConfigViewController *_configView; /*!< @brief Our parent ConfigView. */
}

/*!
 @brief Standard constructor.

 @param connections
 @param configView
 @return ConnectionListController instance.
 */
+ (ConnectionListController *)newWithConnections:(NSArray *)connections andConfigView:(ConfigViewController *)configView;

@end
