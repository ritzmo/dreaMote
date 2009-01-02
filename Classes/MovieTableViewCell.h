//
//  MovieTableViewCell.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/MovieProtocol.h"

#import "FuzzyDateFormatter.h"

// cell identifier for this custom cell
extern NSString *kMovieCell_ID;

@interface MovieTableViewCell : UITableViewCell {

@private	
	NSObject<MovieProtocol> *_movie;
	UILabel *_eventNameLabel;
	UILabel *_eventTimeLabel;
	FuzzyDateFormatter *_formatter;
}

@property (nonatomic, retain) NSObject<MovieProtocol> *movie;
@property (nonatomic, retain) UILabel *eventNameLabel;
@property (nonatomic, retain) UILabel *eventTimeLabel;
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end


