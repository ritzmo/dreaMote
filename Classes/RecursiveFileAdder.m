//
//  RecursiveFileAdder.m
//  dreaMote
//
//  Created by Moritz Venn on 13.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "RecursiveFileAdder.h"

#import "RemoteConnectorObject.h"

#import <XMLReader/SaxXmlReader.h>

@interface RecursiveFileAdder()
- (void)fetchData;
@property (nonatomic, unsafe_unretained) NSObject<RecursiveFileAdderDelegate> *delegate;
@end

@implementation RecursiveFileAdder

@synthesize delegate = _delegate;

- (id)initWithPath:(NSString *)path
{
	if((self = [super init]))
	{
		_remainingPaths = [[NSMutableArray alloc] initWithObjects:path, nil];
	}
	return self;
}

/* add file to list */
- (void)addFile: (NSObject<FileProtocol> *)file
{
	// directory
	if(file.isDirectory)
	{
		// check if this is ".."
		NSString *sref = file.sref;
		NSRange rangeOfString = [sref rangeOfString:file.root];
		if(rangeOfString.location == NSNotFound) return;

		// it's not, add to our queue
		[_remainingPaths addObject:sref];
	}
	// file
	else if(file != nil)
	{
		[_delegate recursiveFileAdder:self addFile:file];
	}
}

- (void)addFiles:(NSArray *)items
{
	for(NSObject<FileProtocol> *file in items)
	{
		[self addFile:file];
	}
}

/* start download of file list */
- (void)fetchData
{
	@autoreleasepool {
		NSString *path = [_remainingPaths lastObject];
		[_remainingPaths removeLastObject];
		_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] fetchFiles:self path:path];
	}
}

- (void)addFilesToDelegate:(NSObject<RecursiveFileAdderDelegate> *)delegate
{
	self.delegate = delegate;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self fetchData]; });
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	// alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];

	// TODO: is it a good idea to try to continue at any cost?
	[self dataSourceDelegateFinishedParsingDocument:dataSource];
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	if([_remainingPaths count])
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ [self fetchData]; });
	}
	else
	{
		[_delegate recursiveFileAdderDoneAddingFiles:self];

		if(dataSource == _xmlReader)
			_xmlReader = nil;
	}
}

@end
