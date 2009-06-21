//
//  SimpleRepeatedViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Repeated Flag selection.
 */
@interface SimpleRepeatedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _repeated; /*!< @brief Current Flags. */
	SEL _selectCallback; /*!< @brief Callback selector. */
	id _selectTarget; /*!< @brief Callback object. */
}

/*!
 @brief Standard constructor.
 
 @param repeated Flags to start with.
 @return SimpleRepeatedViewController instance.
 */
+ (SimpleRepeatedViewController *)withRepeated: (NSInteger)repeated;

/*!
 @brief Set Callback Target.
 
 @param target Callback object.
 @param action Callback selector.
 */
- (void)setTarget: (id)target action: (SEL)action;



/*!
 @brief Repeated Flags.
 */
@property (assign) NSInteger repeated;

@end

