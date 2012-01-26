//
//  FileXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "FileXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/File.h>

#import "NSObject+Queue.h"

static const char *kEnigma2FileElement = "e2file";
static const NSUInteger kEnigma2FileElementLength = 7;
static const char *kEnigma2FileIsDirectory = "e2isdirectory";
static const NSUInteger kEnigma2FileIsDirectoryLength = 14;
static const char *kEnigma2FileRoot = "e2root";
static const NSUInteger kEnigma2FileRootLength = 7;

@interface Enigma2FileXMLReader()
@property (nonatomic, strong) NSObject<FileProtocol> *currentFile;
@end

@implementation Enigma2FileXMLReader

@synthesize currentFile;

/* initialize */
- (id)initWithDelegate:(NSObject<FileSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		if([delegate respondsToSelector:@selector(addFiles:)])
			self.currentItems = [NSMutableArray arrayWithCapacity:kBatchDispatchItemsCount];
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<FileProtocol> *fakeObject = [[GenericFile alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[(NSObject<FileSourceDelegate> *)_delegate addFile:fakeObject];
	[super errorLoadingDocument:error];
}

- (void)finishedParsingDocument
{
	if(self.currentItems.count)
	{
		[(NSObject<FileSourceDelegate> *)_delegate addFiles:self.currentItems];
		[self.currentItems removeAllObjects];
	}
	[super finishedParsingDocument];
}

/*
 Example:
<?xml version="1.0" encoding="UTF-8"?>
<e2filelist>
 <e2file>
  <e2servicereference>/</e2servicereference>
  <e2isdirectory>True</e2isdirectory>
  <e2root>/hdd/MyMP3s</e2root>
 </e2file>
 <e2file>
  <e2servicereference>/hdd/MyMP3s/audio.mp3</e2servicereference>
  <e2isdirectory>False</e2isdirectory>
  <e2root>/hdd/MyMP3s</e2root>
 </e2file>
<e2filelist>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2FileElement, kEnigma2FileElementLength))
	{
		self.currentFile = [[GenericFile alloc] init];
		currentFile.valid = YES;
	}
	else if(	!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength)
			||	!strncmp((const char *)localname, kEnigma2FileRoot, kEnigma2FileRootLength)
			||	!strncmp((const char *)localname, kEnigma2FileIsDirectory, kEnigma2FileIsDirectoryLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2FileElement, kEnigma2FileElementLength))
	{
		if(currentFile)
		{
			if(self.currentItems)
			{
				[self.currentItems addObject:currentFile];
				if(self.currentItems.count >= kBatchDispatchItemsCount)
				{
					NSArray *dispatchArray = [self.currentItems copy];
					[self.currentItems removeAllObjects];
					[[_delegate queueOnMainThread] addFiles:dispatchArray];
				}
			}
			else
				[[_delegate queueOnMainThread] addFile:currentFile];
		}
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		if([currentString isEqualToString:@"None"])
		{
			currentFile.title = NSLocalizedString(@"<Filesystems>", @"Label for Filesystems Item in MediaPlayer Filelist");
			currentFile.sref = @"Filesystems";
		}
		else if([currentString isEqualToString:@"empty"])
		{
			self.currentFile = nil;
		}
		else
		{
			currentFile.sref = currentString;
		}
	}
	else if(!strncmp((const char *)localname, kEnigma2FileRoot, kEnigma2FileRootLength))
	{
		if([currentString isEqualToString:@"playlist"])
		{
			NSArray *comps = [currentFile.sref componentsSeparatedByString:@"/"];
			currentFile.title = [comps lastObject];
		}
		else
		{
			currentFile.title = [currentFile.sref stringByReplacingOccurrencesOfString:currentString withString:@""];
		}
		currentFile.root = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2FileIsDirectory, kEnigma2FileIsDirectoryLength))
	{
		currentFile.isDirectory = [currentString isEqualToString:@"True"];
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
