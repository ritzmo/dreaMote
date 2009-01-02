//
//  Bouquet.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXMLElement;

#import "ServiceProtocol.h"

@interface NeutrinoBouquet : NSObject <ServiceProtocol>
{
@private
	CXMLElement *_node;
}

- (id)initWithNode: (CXMLElement *)node;

@end
