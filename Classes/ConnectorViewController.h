//
//  ConnectorViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
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
	NSInteger _selectedItem; /*!< @brief Selected Item. */
	id<ConnectorDelegate> _delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard Constructor.
 
 @param connectorKey Selected Item.
 @return ConnectorViewController instance.
 */
+ (ConnectorViewController *)withConnector: (NSInteger) connectorKey;

/*!
 @brief Set Delegate.
 
 The delegate will be called back when disappearing to inform it about the newly selected
 connector id.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<ConnectorDelegate>) delegate;



/*!
 @brief Selected Item.
 */
@property (nonatomic) NSInteger selectedItem;

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
