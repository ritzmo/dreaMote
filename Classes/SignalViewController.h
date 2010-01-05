//
//  SignalViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SignalSourceDelegate.h"

/*!
 @brief Signal View.
 
 Allows to display SNR(dB)/AGC/BER as long as RemoteConnector supports it.
 */
@interface SignalViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													SignalSourceDelegate>
{
@private
	NSTimer *_timer; /*!< @brief NSTimer to refresh data. */
	UISlider *_snr; /*!< @brief SNR % Slider. */
	UISlider *_agc; /*!< @brief AGC % Slider. */
	UITableViewCell *_snrdBCell; /*!< @brief Cell containing SNR dB. */
	UITableViewCell *_berCell; /*!< @brief Cell containing BER. */
	BOOL _hasSnrdB; /*!< @brief SNR dB value is valid. */
}

@end
