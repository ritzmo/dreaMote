//
//  Signal.h
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Generic Signal.
 */
@interface Signal : NSObject
{
@private
	float _snrdb; /*!< SNR in dB */
	NSInteger _snr; /*!< SNR in % */
	NSInteger _ber; /*!< BER */
	NSInteger _agc; /*!< AGC in % */
}

/*!
 @brief SNR in dB.
 */
@property (assign) float snrdb;

/*!
 @brief SNR.
 */
@property (assign) NSInteger snr;

/*!
 @brief BER.
 */
@property (assign) NSInteger ber;

/*!
 @brief AGC.
 */
@property (assign) NSInteger agc;

@end
