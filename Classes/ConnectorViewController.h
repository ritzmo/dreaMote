//
//  ConnectorViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Connector Selection.
 
 Allows to select a RemoteConnector to be used for a connection.
 Also allows to start an "autodetection" routine.
 */
@interface ConnectorViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _selectedItem; /*!< @brief Selected Item. */
	SEL _selectCallback; /*!< @brief Callback Selector. */
	id _selectTarget; /*!< @brief Callback Object. */
}

/*!
 @brief Standard Constructor.
 
 @param connectorKey Selected Item.
 @return ConnectorViewController instance.
 */
+ (ConnectorViewController *)withConnector: (NSInteger) connectorKey;

/*!
 @brief Set Callback Target.
 
 @param target Callback object.
 @param action Callback selector.
 */
- (void)setTarget: (id)target action: (SEL)action;



/*!
 @brief Selected Item.
 */
@property (nonatomic) NSInteger selectedItem;

@end

