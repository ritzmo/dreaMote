//
//  MessageTypeViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Message Type Selector.
 */
@interface MessageTypeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _selectedItem; /*!< @brief Selected Item. */
	SEL _selectCallback; /*!< @brief Callback Selector. */
	id _selectTarget; /*!< @brief Callback object. */
}

/*!
 @brief Standard constructor.
 
 @param typeKey Selected message type.
 @return MessageTypeViewController instance.
 */
+ (MessageTypeViewController *)withType: (NSInteger) typeKey;

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
