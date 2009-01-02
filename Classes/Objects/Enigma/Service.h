//
//  Service.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXMLNode;

#import "ServiceProtocol.h"

@interface EnigmaService : NSObject <ServiceProtocol>
{
@private
	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
