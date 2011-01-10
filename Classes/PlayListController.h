//
//  PlayListController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileListView.h"

@interface PlayListController : UIViewController {
@protected
	FileListView *_playlist; /*!< @brief Playlist. */
}

/*!
 @brief Get/Set Playlist.
 */
@property (nonatomic, retain) FileListView *playlist;


@end
