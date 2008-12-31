//
//  BaseXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CXMLDocument.h"
#import "RemoteConnector.h"

@interface BaseXMLReader : NSObject
{
@private
	id		_target;
	SEL		_addObject;
@protected
	CXMLDocument *_parser;
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) id target;
@property (nonatomic) SEL addObject;

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error connectorType:(enum availableConnectors)connector;

// XXX: do we really want them to be public?
- (void)parseAllEnigma2;
- (void)parseAllEnigma1;
- (void)parseAllNeutrino;

@end
