//
//  MediaPlayerDetailsController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileListView.h"
#import "MediaPlayerController.h"
#import "MetadataProtocol.h"
#import "MetadataSourceDelegate.h"
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */

@class BaseXMLReader;

@interface MediaPlayerDetailsController : MediaPlayerController <UITableViewDelegate,
															UITableViewDataSource,
															MGSplitViewControllerDelegate,
															MetadataSourceDelegate>
{
@private
	NSObject<MetadataProtocol> *_currentTrack; /*!< @brief Meta-information to currently playing track. */
	UIImage *_currentCover; /*!< @brief Coverart to currently playing track. */
	UITableView *_tableView; /*!< @brief "Main" Table view. */

	BaseXMLReader *_xmlReaderMetadata; /*!< @brief Track metadata. */
}

/*!
 @brief Assign a new playlist and make ourselves its delegate.
 */
@property (nonatomic, strong) FileListView *playlist;

@property (nonatomic, readonly) UITableView *tableView;

@end
