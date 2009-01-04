//
//  Enigma1Connector.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

#import "CXMLDocument.h"

@interface Enigma1Connector : NSObject <RemoteConnector> {
@private
	NSURL *baseAddress;

	CXMLDocument *cachedBouquetsXML;
}

@end
