//
//  SimpleRepeatedViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.06.09.
//  Copyright 2009-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SimpleRepeatedDelegate;

/*!
 @brief Repeated Flag selection.
 
 Allows to select repeated flags from a simple set of available values.
 It's adjusted to the Enigma and Enigma2 model of repeating timers thus it only
 offers weakly repetitions based on days.
 */
@interface SimpleRepeatedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _repeated; /*!< @brief Current Flags. */
	id<SimpleRepeatedDelegate> _delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard constructor.
 
 @param repeated Flags to start with.
 @return SimpleRepeatedViewController instance.
 */
+ (SimpleRepeatedViewController *)withRepeated: (NSInteger)repeated;

/*!
 @brief Set Delegate.
 
 The delegate will be called back when disappearing to inform it about the newly selected
 repeated flags.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<SimpleRepeatedDelegate>) delegate;



/*!
 @brief Repeated Flags.
 */
@property (assign) NSInteger repeated;

@end



/*!
 @brief SimpleRepeatedViewController Delegate.
 
 Implements callback functionality for SimpleRepeatedViewController.
 */
@protocol SimpleRepeatedDelegate <NSObject>

/*!
 @brief Repeated flags were selected.
 
 @param newRepeated New repeated flags.
 */
- (void)simpleRepeatedSelected: (NSNumber *)newRepeated;

@end
