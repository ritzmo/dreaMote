//
//  MediaPlayerController.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EventSourceDelegate.h" /* EventSourceDelegate */
#import "FileListView.h" /* FileListDelegate */
#import "ServiceSourceDelegate.h" /* ServiceSourceDelegate */


/*!
 @brief Media Player Controller.
 */
@interface MediaPlayerController : UIViewController <FileListDelegate, EventSourceDelegate,
													ServiceSourceDelegate>
{
@private
	UIPopoverController *popoverController;
	NSTimer *_timer; /*!< @brief Refresh timer. */
	UIView *_controls; /*!< @brief Media Player controls. */
	
	CGRect _landscapeControlsFrame; /*!< @brief Landscape frame of controls. */
	CGRect _portraitControlsFrame; /*!< @brief Portrait frame of controls. */

	CXMLDocument *_currentXMLDoc; /*!< @brief Currently played. */
@protected
	FileListView *_fileList; /*!< @brief File browser. */
	FileListView *_playlist; /*!< @brief Playlist. */
}

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

@end
