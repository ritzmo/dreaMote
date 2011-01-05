//
//  MediaPlayerController.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FileListView.h" /* FileListDelegate */

/*!
 @brief Media Player Controller.
 */
@interface MediaPlayerController : UIViewController <FileListDelegate>
{
@private
	FileListView *_fileList; /*!< @brief File browser. */
	FileListView *_playlist; /*!< @brief Playlist. */
	UIView *_frontend; /*!< @brief Main Interface. */
	UIView *_controls; /*!< @brief Media Player controls. */
	
	CGRect _landscapeControlsFrame; /*!< @brief Landscape frame of controls. */
	CGRect _portraitControlsFrame; /*!< @brief Portrait frame of controls. */
}

/*!
 @brief Flip Views.
 
 @param sender Unused parameter required by Buttons.
 */
- (IBAction)flipView:(id)sender;

@end
