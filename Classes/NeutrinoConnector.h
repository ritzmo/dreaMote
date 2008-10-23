//
//  NeutrinoConnector.h
//  Untitled
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef ENABLE_NEUTRINO_CONNECTOR

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

@interface NeutrinoConnector : NSObject <RemoteConnector> {
@private
	NSURL *baseAddress;
	NSMutableDictionary *serviceCache;

	id serviceTarget;
	SEL serviceSelector;
}

@property (nonatomic, retain) NSURL *baseAddress;

@end

#endif