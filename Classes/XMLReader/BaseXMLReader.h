//
//  BaseXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
#define DataDownloaderRunMode @"your_namespace.run_mode"
#import "CXMLPushDocument.h"
#else
#import "CXMLDocument.h"
#endif

#import "RemoteConnector.h"

@interface BaseXMLReader : NSObject
{
@private
	id		_target;
	SEL		_addObject;
#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	BOOL	finished;
@protected
	CXMLPushDocument *_parser;
#else
@protected
	CXMLDocument *_parser;
#endif
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) id target;
@property (nonatomic) SEL addObject;

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error connectorType:(enum availableConnectors)connector;

@end
