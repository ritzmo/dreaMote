//
//  Enigma2Connector.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

/*!
 @brief Connector for Enigma2 based STBs.
 */
@interface Enigma2Connector : NSObject <RemoteConnector> {
@private
	NSURL *_baseAddress; /*!< @brief Base URL of STB */
	NSString *_password; /*!< @brief Connection password */
	NSString *_username; /*!< @brief Connection username */
	BOOL _wasWarned; /*!< @brief User was warned about old software this session */
	BOOL _advancedRc; /*!< @brief Uses advanced remote control. */
}

@end
