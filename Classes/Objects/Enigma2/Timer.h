//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "TimerProtocol.h"
#import "ServiceProtocol.h"

/*!
 @brief Timer in Enigma2.
 */
@interface Enigma2Timer : NSObject <TimerProtocol>
{
@private
	NSString *_eit; /*!< @brief Event Id. */
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */
	BOOL _disabled;  /*!< @brief Disabled? */
	NSString *_title; /*!< @brief Title. */
	NSString *_tdescription; /*!< @brief Description. */
	NSInteger _repeated; /*!< @brief Repeated Flags. */
	BOOL _justplay; /*!< @brief Justplay? */
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
	NSInteger _state; /*!< @brief State. */
	NSInteger _afterevent; /*!< @brief After Event Action. */
	BOOL _isValid; /*!< @brief Valid or Fake Timer? */
	NSString *_timeString; /*!< @brief Cache for Begin/End Textual representation. */

	// Unfortunately we need some helpers...
	// Why I hear you ask? Because the values can actually evaluate to false
	// and the code would just re-read the values all over again...
	BOOL _disabledSet; /*!< @brief Disabled was set. */
	BOOL _justplaySet; /*!< @brief Justplay was set. */
	BOOL _stateSet; /*!< @brief State was set. */
	BOOL _aftereventSet; /*!< @brief After Event Action was set. */
	BOOL _repeatedSet; /*!< @brief Repeated was set. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Timer. */
}


/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Timer.
 @return Enigma2Timer instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
