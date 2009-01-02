//
//  Service.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ServiceProtocol.h"

@interface Service : NSObject <ServiceProtocol>
{
@private
	NSString *_sref;
	NSString *_sname;
}

- (id)initWithService:(NSObject<ServiceProtocol> *)service;

@end
