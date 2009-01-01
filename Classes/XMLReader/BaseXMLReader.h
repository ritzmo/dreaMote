//
//  BaseXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
#define DataDownloaderRunMode @"your_namespace.run_mode"
#import "CXMLPushDocument.h"
typedef CXMLPushDocument OurXMLDocument;
#else
#import "CXMLDocument.h"
typedef CXMLDocument OurXMLDocument;
#endif

#import "RemoteConnector.h"

@interface BaseXMLReader : NSObject
{
@private
	BOOL	finished;
@protected
	id		_target;
	SEL		_addObject;
	OurXMLDocument *_parser;
}

- (id)initWithTarget:(id)target action:(SEL)action;

@property (readonly) BOOL finished;

- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error;

@end
