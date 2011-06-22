//
//  MediaPlayerController.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AboutSourceDelegate.h" /* AboutSourceDelegate */
#import "EventSourceDelegate.h" /* EventSourceDelegate */
#import "FileListView.h" /* FileListDelegate */
#import "MBProgressHUD.h" /* MBProgressHUDDelegate */
#import "RecursiveFileAdder.h" /* RecursiveFileAdderDelegate */
#import "ServiceSourceDelegate.h" /* ServiceSourceDelegate */
#import "MediaPlayerShuffleDelegate.h" /* MediaPlayerShuffleDelegate */


/*!
 @brief Ways to retrieve currently playing track.
 */
enum retrieveCurrentUsing {
	/*!
	 @brief Retrieve currently playing track through "About"
	 */
	kRetrieveCurrentUsingAbout,
	/*!
	 @brief Retrieve currently playing track through "Current"
	 */
	kRetrieveCurrentUsingCurrent,
	/*!
	 @brief No known way to retrieve currently playing track
	 */
	kRetrieveCurrentUsingNone,
};

/*!
 @brief Media Player Controller.
 */
@interface MediaPlayerController : UIViewController <FileListDelegate, EventSourceDelegate,
													RecursiveFileAdderDelegate,
													MediaPlayerShuffleDelegate,
													AboutSourceDelegate, MBProgressHUDDelegate,
													ServiceSourceDelegate, UIActionSheetDelegate>
{
@private
	UIPopoverController *popoverController; /*!< @brief Current Popover Controller. */
	MBProgressHUD *progressHUD; /*!< @brief Activity view (for mass add to playlist). */
	BOOL _adding; /*!< @brief Adding tracks to playlist. */
	BOOL _massAdd; /*!< @brief Performing a mass-add operation. */
	NSTimer *_timer; /*!< @brief Refresh timer. */
	UIView *_controls; /*!< @brief Media Player controls. */

	CGRect _landscapeControlsFrame; /*!< @brief Landscape frame of controls. */
	CGRect _portraitControlsFrame; /*!< @brief Portrait frame of controls. */

	CXMLDocument *_currentXMLDoc; /*!< @brief Currently played. */
	enum retrieveCurrentUsing _retrieveCurrentUsing; /*!< @brief Way to retrieve currently playing track. */

	UIBarButtonItem *_shuffleButton;  /*!< @brief "Shuffle" Button. */
	UIBarButtonItem *_deleteButton;
	float _progressActions; /*!< @brief Shuffle/Delete actions left or -1 on unknown. */
@protected
	UIBarButtonItem *_addFolderItem; /*!< @brief "Add Folder" Button. */
	UIBarButtonItem *_addPlayToggle; /*!< @brief Add/Play Toggle. */
	FileListView *_fileList; /*!< @brief File browser. */
	FileListView *_playlist; /*!< @brief Playlist. */
}

/*!
 @brief Clear Playlist.

 @param sender Unused parameter required by Buttons.
 */
- (IBAction)clearPlaylist:(id)sender;

/*!
 @brief Multi-Delete from Playlist.

 @param sender Unused parameter required by Buttons.
 */
- (IBAction)multiDelete:(id)sender;

/*!
 @brief Flip Views.
 
 @param sender Unused parameter required by Buttons.
 */
- (IBAction)flipView:(id)sender;

/*!
 @brief Create custom Button.
 
 @param frame Button Frame.
 @param imagePath Path to Button Image.
 @param keyCode RC Code.
 @return UIButton instance.
 */
- (UIButton*)newButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;

/*!
 @brief New track started playing.
 
 @note Not used by us, but interesting for inheriting classes, e.g. MediaPlayerDetailsController
 */
- (void)newTrackPlaying;

/*!
 @brief Hide toolbar.
 */
- (void)hideToolbar;

/*!
 @brief Show toolbar.
 */
- (void)showToolbar;

/*!
 @brief Shuffle Playlist.

 @param sender Unused parameter required by Buttons.
 */
- (IBAction)shuffle:(id)sender;

/*!
 @brief Default implementation of xml parser error callback.
 */
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error;

/*!
 @brief Default implementation of xml parser success callback.
 */
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document;

@property (nonatomic, readonly) UIBarButtonItem *deleteButton;
@property (nonatomic, readonly) UIBarButtonItem *shuffleButton;

@end
