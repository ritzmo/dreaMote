//
//  Enigma2Connector.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

typedef enum
{
	/*! @brief Not yet processed. */
	WEBIF_VERSION_UNKNOWN = 0,
	/*! @brief Old and unhandled version. */
	WEBIF_VERSION_OLD = 1,
	/*! @brief Sleeptimer added. */
	WEBIF_VERSION_1_6_5 = 2,
	/*! @brief Save/Load/Clear MP playlist. */
	WEBIF_VERSION_1_6_8 = 3,
	/*! @brief Upper bound. */
	WEBIF_VERSION_MAX,
} webifVersion;

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
	webifVersion _webifVersion; /*!< @brief Version of remove web interface. */
}

@end
