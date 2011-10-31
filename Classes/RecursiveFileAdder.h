//
//  RecursiveFileAdder.h
//  dreaMote
//
//  Created by Moritz Venn on 13.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileListView.h"
#import "FileSourceDelegate.h"

@class BaseXMLReader;
@protocol RecursiveFileAdderDelegate;

@interface RecursiveFileAdder : NSObject <FileSourceDelegate>
{
@private
	BaseXMLReader *_xmlReader;
	NSMutableArray *_remainingPaths;
	NSObject<RecursiveFileAdderDelegate> __unsafe_unretained *_delegate;
}

- (id)initWithPath:(NSString *)path;
- (void)addFilesToDelegate:(NSObject<RecursiveFileAdderDelegate> __unsafe_unretained *)delegate;

@end

@protocol RecursiveFileAdderDelegate
- (void)recursiveFileAdder:(RecursiveFileAdder *)rfa addFile:(NSObject<FileProtocol> *)file;
- (void)recursiveFileAdderDoneAddingFiles:(RecursiveFileAdder *)rfa;
@end