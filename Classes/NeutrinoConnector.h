//
//  NeutrinoConnector.h
//  dreaMote
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

#import "CXMLDocument.h"

/*!
 @interface NeutrinoConnector
 @abstract Connector for Neutrino based STBs.
 */
@interface NeutrinoConnector : NSObject <RemoteConnector> {
@private
	NSURL *baseAddress;
	CXMLDocument *cachedBouquetsXML;
}

@end
