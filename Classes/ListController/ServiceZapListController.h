//
//  ServiceZapListController.h
//  dreaMote
//
//  Created by Moritz Venn on 13.02.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Zap actions.

 @note Keep in sync with the row indices of the fully populated list.
 */
typedef enum
{
	zapActionRemote = 0,
	zapActionOPlayer = 1,
	zapActionOPlayerLite = 2,
	zapActionBuzzPlayer = 3,
	zapActionYxplayer = 4,
	zapActionGoodPlayer = 5,
	zapActionAcePlayer = 6,
    zapActionCustomUrl = 7,
	zapActionMax = 8,
} zapAction;

@class ServiceZapListController;

/*!
 @brief Callback type for zap callbacks.

 @param zapListController controller the selection was done in
 @param selectedAction action the user selected
 */
typedef void (^zap_callback_t)(ServiceZapListController *zapListController, zapAction selectedAction);

/*!
 @brief Table showing actions you can execute for a specific service.

 @note This table is used only on the iPad to make the UI more appealing, as a
 UIActionSheet (which is used on the iPhone) disturbs the ui flow too much while a popover
 appears more like a "side-action".
 @note For convenience reasons the iPhone uses this class to manage the action sheet too.
 */
@interface ServiceZapListController : UIViewController <UITableViewDelegate,
														UIActionSheetDelegate,
														UITableViewDataSource>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	BOOL hasAction[zapActionMax]; /*!< @brief Cache of supported zap actions */
	UIActionSheet *_actionSheet; /*!< @brief Action sheet if ran on iPhone/iPod Touch. */
}

/*!
 @brief Is the device able to play back a stream?
 Will return YES if a supported streaming-capable media player is installed AND
 the current connector supports streaming.

 @return YES if streaming is possible, else NO.
 */
+ (BOOL)canStream;

/*!
 @brief Is a streaming capable player installed?
 Will return YES if a supported streaming-capable media player is installed.

 @return YES if a player is installed, else NO.
 */
+ (BOOL)streamPlayerInstalled;

/*!
 @brief Return the stream player names as used in the config list.

 @param zapAction Player Action
 @return Name of player.
 */
+ (NSString *)playerName:(zapAction)playerAction;

/*!
 @brief Return list of installed stream player names.
 @return Array with names.
 */
+ (NSArray *)playerNames;

/*!
 @brief Translate an index in the list of players to a zapAction.
 @param index Index in the playerNames array.
 @return Corresponding action.
 */
+ (zapAction)zapActionForIndex:(NSInteger)index;

/*!
 @brief Translate zap action to an index in the list of players.
 @param action Action to look for.
 @return Index in the playerNames array.
 */
+ (NSInteger)indexForZapAction:(zapAction)action;

/*!
 @brief Show Alert.
 Instead of a Table the iPhone uses an Alert Sheet to display the possible "zapping" methods.
 To reduce the possibility of errors by code duplication the sheet is managed in this class.

 @param delegate Delegate to be called back.
 @param tabBar Tab bar to show action sheet from.
 */
+ (ServiceZapListController *)showAlert:(zap_callback_t)callback fromTabBar:(UITabBar *)tabBar;

/*!
 @brief Open external streaming application

 @param streamingUrl URL of the stream.
 @param action zapAction matching the application to open.
 */
- (void)openStream:(NSURL *)streamingUrl withAction:(zapAction)action;
+ (void)openStreamWithViewController:(NSURL *)streamingUrl withAction:(zapAction)action withViewController:(UIViewController*) vc;

/*!
 @brief Callback.
 */
@property (nonatomic, copy) zap_callback_t callback;

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
