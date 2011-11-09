//
//  ConnectorViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ConnectorDelegate;

/*!
 @brief Connector Selection.
 
 Allows to select a RemoteConnector to be used for a connection.
 Also allows to start an "autodetection" routine.
 */
@interface ConnectorViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
}
/*!
 @brief Standard Constructor.
 
 @param connectorKey Selected Item.
 @return ConnectorViewController instance.
 */
+ (ConnectorViewController *)withConnector: (NSInteger) connectorKey;



/*!
 @brief Delegate.
 
 The delegate will be called back when disappearing to inform it about the newly selected
 connector id.
 */
@property (nonatomic, unsafe_unretained) id<ConnectorDelegate> delegate;

/*!
 @brief Selected Item.
 */
@property (nonatomic) NSInteger selectedItem;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end



/*!
 @brief ConnectorViewController Delegate.
 
 Implements callback functionality for ConnectorViewController.
 */
@protocol ConnectorDelegate <NSObject>

/*!
 @brief Connector was selected.
 
 @param newConnector Selected Connector.
 */
- (void)connectorSelected: (NSNumber*) newConnector;

@end
