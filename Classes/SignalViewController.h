//
//  SignalViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignalViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSTimer *timer;
	UISlider *_snr;
	UISlider *_agc;
	UITableViewCell *_snrdBCell;
	UITableViewCell *_berCell;
	BOOL _hasSnrdB;
}

@end
