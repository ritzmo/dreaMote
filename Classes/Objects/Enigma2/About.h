//
//  About.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "AboutProtocol.h"

@class Harddisk;

@interface Enigma2About : NSObject<AboutProtocol>
{
@private
	Harddisk *_hdd; /*!< @brief Information on Harddisk. */
	NSMutableArray *_tuners; /*!< @brief List of available Tuners. */

	CXMLNode *_node; /*!< @brief CXMLNode describing receiver information. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing receiver information.
 @return Enigma2About instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
