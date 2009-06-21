//
//  AfterEventViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief After Event Selector.
 
 Allows to select an after event action from the list defined by enum afterEvent.
 */
@interface AfterEventViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _selectedItem; /*!< @brief Selected Item. */
	SEL _selectCallback; /*!< @brief Callback Selector. */
	id _selectTarget; /*!< @brief Callback object. */
	BOOL _showAuto; /*!< @brief Show "kAfterEventAuto" Item? */
}

/*!
 @brief Standard Constructor.
 
 Open new instance of this ViewController with given settings.
 
 @param afterEvent Selected After Event Action.
 @param showAuto Show "kAfterEventAuto" Item?
 @return AfterEventViewController instance.
 */
+ (AfterEventViewController *)withAfterEvent: (NSInteger)afterEvent andAuto: (BOOL)showAuto;

/*!
 @brief Set Callback Target.
 
 @param target Callback object.
 @param action Callback selector.
 */
- (void)setTarget: (id)target action: (SEL)action;



/*!
 @brief Selected Item.
 */
@property (assign) NSInteger selectedItem;

/*!
 @brief Show "kAfterEventAuto" Item?
 */
@property (assign) BOOL showAuto;

@end

