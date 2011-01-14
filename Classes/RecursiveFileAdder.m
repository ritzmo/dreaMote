//
//  RecursiveFileAdder.m
//  dreaMote
//
//  Created by Moritz Venn on 13.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "RecursiveFileAdder.h"

#import "RemoteConnectorObject.h"

@interface RecursiveFileAdder()
- (void)fetchData;
@property (nonatomic, retain) NSObject<RecursiveFileAdderDelegate> *delegate;
@end

@implementation RecursiveFileAdder

@synthesize delegate = _delegate;

- (id)initWithPath:(NSString *)path
{
	if((self = [super init]))
	{
		_remainingPaths = [[NSMutableArray arrayWithObject:path] retain];
	}
	return self;
}

- (void)dealloc
{
	[_remainingPaths release];
	[_delegate release];

	[super dealloc];
}

/* add file to list */
- (void)addFile: (NSObject<FileProtocol> *)file
{
	// end of list
	if(file == nil)
	{
		if([_remainingPaths count])
		{
			[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
		}
		else
		{
			[_delegate recursiveFileAdderDoneAddingFiles:self]; 
		}
	}
	// directory
	else if(file.isDirectory)
	{
		// check if this is ".."
		NSString *original = file.sref;
		NSRange rangeOfString = [file.sref rangeOfString:file.root];
		if(rangeOfString.location == NSNotFound) return;

		// it's not, add a copy of it to our queue
		NSString *copy = [original copy];
		[_remainingPaths addObject:copy];
		[copy release];
	}
	// file
	else
	{
		[_delegate recursiveFileAdder:self addFile:file];
	}
}

/* start download of file list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_fileXMLDoc release];
	NSString *path = [[_remainingPaths lastObject] retain];
	[_remainingPaths removeLastObject];
	_fileXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchFiles:self path:path] retain];
	[path release];
	[pool release];
}

- (void)addFilesToDelegate:(NSObject<RecursiveFileAdderDelegate> *)delegate
{
	self.delegate = delegate;
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

@end
