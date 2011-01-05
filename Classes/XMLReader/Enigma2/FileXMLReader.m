//
//  FileXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "FileXMLReader.h"

#import "../../Objects/Enigma2/File.h"
#import "../../Objects/Generic/File.h"

@implementation Enigma2FileXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<FileSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_delegate release];
	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<FileProtocol> *fakeObject = [[GenericFile alloc] init];
	fakeObject.sref = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: @selector(addFile:)
								withObject: fakeObject
							 waitUntilDone: NO];
	[fakeObject release];
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
- (void)parseFull
{
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2filelist/e2file" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		// An e2event in the xml represents an event, so create an instance of it.
		NSObject<FileProtocol> *newFile = [[Enigma2File alloc] initWithNode: (CXMLNode *)resultElement];

		[_delegate performSelectorOnMainThread: @selector(addFile:)
									withObject: newFile
								 waitUntilDone: NO];
		[newFile release];
	}

	// send invalid element to indicate that we're done with parsing
	[_delegate performSelectorOnMainThread: @selector(addFile:)
								withObject: nil
							 waitUntilDone: NO];
}

@end
