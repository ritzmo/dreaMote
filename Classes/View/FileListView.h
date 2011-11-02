//
//  FileListView.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EGORefreshTableHeaderView.h"
#import "FileSourceDelegate.h"

@class BaseXMLReader;
@protocol FileProtocol;
@protocol FileListDelegate;

@interface FileListView : UITableView <UITableViewDelegate, UITableViewDataSource,
										EGORefreshTableHeaderDelegate, FileSourceDelegate>
{
@private
	NSString *_path; /*!< @brief Current path. */
	BOOL _isPlaylist; /*!< @brief Is playlist? */
	NSInteger _playing; /*!< @brief Item marked as currently playing. */

	BaseXMLReader *_xmlReader; /*!< @brief XML Reader. */
	EGORefreshTableHeaderView *_refreshHeaderView; /*!< @brief "Pull up to refresh". */
	NSMutableArray *_files; /*!< @brief Current List of Files. */
	NSMutableArray *_selected; /*!< @brief List of selected Files. */
}

/*!
 @brief Get list of files in this folder.
 Uses the normal fileSelected callback for indication.
 */
- (void)getFiles;

/*!
 @brief Redownload data and refresh contents.
 */
- (void)refreshData;

/*!
 @brief Remove track from list
 @note Normally called by delegate after remove from remote list succeeded

 @param file File that was removed
 */
- (void)removeFile:(NSObject<FileProtocol> *)file;

/*!
 @brief Select item by title

 @param filename Filename of the file to select
 @return YES if playing track was changed.
 */
- (BOOL)selectPlayingByTitle:(NSString *)filename;

/*!
 @brief Delegate.
 */
@property (nonatomic, unsafe_unretained) UIViewController<FileListDelegate> *fileDelegate;
@property (nonatomic) BOOL isPlaylist;

/*!
 @brief Currently reloading?
 */
@property (nonatomic) BOOL reloading;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, readonly) NSMutableArray *files;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *selectedFiles;

@end

@protocol FileListDelegate
/*!
 @brief File was selected.

 @param fileListView View the file was selected in
 @param file File in question
 */
- (void)fileListView:(FileListView *)fileListView fileSelected:(NSObject<FileProtocol> *)file;

/*!
 @brief File was "multiselected".
 This does not take into account the files current selection status.
 So for selection & subsequent deselection two events are emitted.

 @param fileListView View the file was (de)selected in
 @param file File in question
 */
- (void)fileListView:(FileListView *)fileListView fileMultiSelected:(NSObject<FileProtocol> *)file;

/*!@brief File was removed.

 @param fileListView View the file was removed in
 @param file File in question
 */
- (void)fileListView:(FileListView *)fileListView fileRemoved:(NSObject<FileProtocol> *)file;
@end
