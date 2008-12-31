//
//  BaseXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import "BaseXMLReader.h"

@interface BaseXMLReader()
- (void)sendErroneousObject;
@end

@implementation BaseXMLReader

@synthesize target = _target;
@synthesize addObject = _addObject;

- (void)dealloc
{
	[_target release];
	[_parser release];

	[super dealloc];
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	BaseXMLReader *xmlReader = [[BaseXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error connectorType:(enum availableConnectors)connector;
{
	// XXX: modify touchxml to allow chunk parsing... might save use some time/resources
	_parser = [[CXMLDocument alloc] initWithContentsOfURL:URL options: 0 error: error];

	// bail out if we encountered an error
	if(error && *error)
	{
		[self sendErroneousObject];
		return;
	}

	switch(connector)
	{
		case kEnigma2Connector:
			[self parseAllEnigma2];
			return;
		case kEnigma1Connector:
			[self parseAllEnigma1];
			return;
		case kNeutrinoConnector:
			[self parseAllNeutrino];
			return;
		default:
			[self sendErroneousObject];
			return;
	}
}

- (void)sendErroneousObject
{
	// XXX: descending classes should implement this
}

- (void)parseAllEnigma2
{
	// XXX: descending classes should implement this
}

- (void)parseAllEnigma1
{
	// XXX: descending classes should implement this
}

- (void)parseAllNeutrino
{
	// XXX: descending classes should implement this
}

@end
