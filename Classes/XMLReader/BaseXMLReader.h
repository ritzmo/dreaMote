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
	BOOL supportsIncremental;
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) id target;
@property (nonatomic) SEL addObject;
@property (readonly) BOOL supportsIncremental;
@property (readonly) BOOL finished;

- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error;
- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error parseImmediately: (BOOL)doParse;

- (void)parseInitial;
- (void)parseFull;
- (id)parseSpecific: (NSString *)identifier;

@end
