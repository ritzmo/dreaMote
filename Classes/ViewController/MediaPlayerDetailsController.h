//
//  MediaPlayerDetailsController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <ViewController/MediaPlayerController.h>

#import <View/FileListView.h>

#import <Objects/MetadataProtocol.h>
#import <Delegates/MetadataSourceDelegate.h>
#import <Delegates/VolumeSourceDelegate.h>
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */

@class SaxXmlReader;

@interface MediaPlayerDetailsController : MediaPlayerController <UITableViewDelegate,
															UITableViewDataSource,
															MGSplitViewControllerDelegate,
															MetadataSourceDelegate,
															VolumeSourceDelegate>
{
@private
	NSObject<MetadataProtocol> *_currentTrack; /*!< @brief Meta-information to currently playing track. */
	UIImage *_currentCover; /*!< @brief Coverart to currently playing track. */
	UITableView *_tableView; /*!< @brief "Main" Table view. */
	UISlider *_volumeSlider; /*!< @brief Slider for the current volume. */

	SaxXmlReader *_xmlReaderMetadata; /*!< @brief Track metadata. */
}

/*!
 @brief Assign a new playlist and make ourselves its delegate.
 */
@property (nonatomic, strong) FileListView *playlist;

@property (nonatomic, readonly) UITableView *tableView;

@end
