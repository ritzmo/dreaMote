//
//  Service.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Objects/Generic/Service.h>

/*!
 @brief Service in Enigma.
 */
@interface EnigmaService : GenericService
{
@private
	BOOL _isBouquet; /*!< @brief For Bouquets: Is this a userbouquet or a Provider?. */
}

@property (nonatomic, assign) BOOL isBouquet;

@end
