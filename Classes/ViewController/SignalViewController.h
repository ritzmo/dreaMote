//
//  SignalViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "SignalSourceDelegate.h"

/*!
 @brief Signal View.
 
 Allows to display SNR(dB)/AGC/BER as long as RemoteConnector supports it.
 */
@interface SignalViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													SignalSourceDelegate>
{
@private
	UITableView *_tableView; /*!< @brief Table View. */
	NSTimer *_timer; /*!< @brief NSTimer to refresh data. */
	UISlider *_snr; /*!< @brief SNR % Slider. */
	UISlider *_agc; /*!< @brief AGC % Slider. */
	UISlider *_interval; /*!< @brief Refresh interval Slider. */
	UISwitch *_audioToggle; /*!< @brief Enable/disable audio. */
	BOOL _hasSnrdB; /*!< @brief SNR dB value is valid. */
	NSTimeInterval _refreshInterval; /*!< @brief Current refresh Interval. */
	AudioComponentInstance toneUnit; /*!< @brief AudioUnit generating audio aid. */
@public
	double frequency; /*!< @brief Current frequency of tone. */
	double sampleRate; /*!< @brief Sample rate for tone. */
	double theta; /*!< @brief Current theta value for tone. */
}

/*!
 @brief Table View.
 */
@property (nonatomic, readonly) UITableView *tableView;

@end
