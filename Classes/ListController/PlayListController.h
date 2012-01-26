//
//  PlayListController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileListView.h"

@interface PlayListController : UIViewController

/*!
 @brief Get "Clear Playlist" Button.
 */
@property (nonatomic, strong) UIBarButtonItem *clearButton;

/*!
 @brief Get "Save Playlist" Button.
 */
@property (nonatomic, strong) UIBarButtonItem *saveButton;

/*!
 @brief Get "Load Playlist" Button.
 */
@property (nonatomic, strong) UIBarButtonItem *loadButton;

/*!
 @brief Get/Set Playlist.
 */
@property (nonatomic, strong) FileListView *playlist;

/*!
 @brief Convenience accessor to tableview / playlist
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
