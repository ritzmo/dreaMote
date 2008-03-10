//
//  Enigma2Connector.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

#define STREAMING_PARSE

@interface Enigma2Connector : NSObject <RemoteConnector> {
@private
	NSString *baseAddress;
}

#ifdef STREAMING_PARSE
- (NSArray *)fetchXmlDocument:(NSString *) myURI :(NSString *) myClass :(NSString *) myElement;
#endif

@property (nonatomic, retain) NSString *baseAddress;

@end
