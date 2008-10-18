//
//  MovieTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Movie.h"

#import "FuzzyDateFormatter.h"

// cell identifier for this custom cell
extern NSString *kMovieCell_ID;

@interface MovieTableViewCell : UITableViewCell {

@private	
	Movie *_movie;
	UILabel *_eventNameLabel;
	UILabel *_eventTimeLabel;
	FuzzyDateFormatter *_formatter;
}

@property (nonatomic, retain) Movie *movie;
@property (nonatomic, retain) UILabel *eventNameLabel;
@property (nonatomic, retain) UILabel *eventTimeLabel;
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end


