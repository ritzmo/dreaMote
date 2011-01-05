//
//  FileListView.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileSourceDelegate.h"

@class CXMLDocument;
@protocol FileProtocol;
@protocol FileListDelegate;

@interface FileListView : UITableView <UITableViewDelegate, UITableViewDataSource,
										FileSourceDelegate>
{
@private
	NSString *_path; /*!< @brief Current path. */
	BOOL _isPlaylist; /*!< @brief Is playlist? */

	CXMLDocument *_fileXMLDoc; /*!< @brief XML Document. */
	UIViewController<FileListDelegate> *_fileDelegate; /*!< @brief Delegate. */
	NSMutableArray *_files; /*!< @brief Current List of Files. */
}

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

@property (nonatomic, retain) UIViewController<FileListDelegate> *fileDelegate;
@property (nonatomic) BOOL isPlaylist;
@property (nonatomic, retain) NSString *path;

@end

@protocol FileListDelegate
/*!
 @brief File was selected.
 
 @param fileListView View the file was selected in
 @param file File in question
 */
- (void)fileListView:(FileListView *)fileListView fileSelected:(NSObject<FileProtocol> *)file;

/*!@brief File was removed.
 
 @param fileListView View the file was removed in
 @param file File in question
 */
- (void)fileListView:(FileListView *)fileListView fileRemoved:(NSObject<FileProtocol> *)file;
@end
