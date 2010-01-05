//
//  Service.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ServiceProtocol.h"

/*!
 @brief Generic Service.
 */
@interface GenericService : NSObject <ServiceProtocol>
{
@private
	NSString *_sref; /*!< @brief Reference. */
	NSString *_sname; /*!< @brief Name. */
}

/*!
 @brief Init with existing Service.

 @note Required to create a Copy.
 @return Service instance.
 */
- (id)initWithService:(NSObject<ServiceProtocol> *)service;

@end
