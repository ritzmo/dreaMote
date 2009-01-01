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
	id		_target;
	SEL		_addObject;
	BOOL	finished;
@protected
	OurXMLDocument *_parser;
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) id target;
@property (nonatomic) SEL addObject;
@property (readonly) BOOL finished;

- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error;

@end
