//
//  SignalViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Signal View.
 */
@interface SignalViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSTimer *timer; /*!< @brief NSTimer to refresh data. */
	UISlider *_snr; /*!< @brief SNR % Slider. */
	UISlider *_agc; /*!< @brief AGC % Slider. */
	UITableViewCell *_snrdBCell; /*!< @brief Cell containing SNR dB. */
	UITableViewCell *_berCell; /*!< @brief Cell containing BER. */
	BOOL _hasSnrdB; /*!< @brief SNR dB value is valid. */
}

@end
