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

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kMovieCell_ID;

/*!
 @brief UITableViewCell optimized to display Movies.
 */
@interface MovieTableViewCell : UITableViewCell
{
@private	
	NSObject<MovieProtocol> *_movie; /*!< @brief Movie. */
	UILabel *_eventNameLabel; /*!< @brief Name Label. */
	UILabel *_eventTimeLabel; /*!< @brief Time Label. */
	FuzzyDateFormatter *_formatter; /*!< @brief Date Formatter instance. */
}

/*!
 @brief Movie.
 */
@property (nonatomic, retain) NSObject<MovieProtocol> *movie;

/*!
 @brief Name Label.
 */
@property (nonatomic, retain) UILabel *eventNameLabel;

/*!
 @brief Time Label.
 */
@property (nonatomic, retain) UILabel *eventTimeLabel;

/*!
 @brief Date Formatter instance.
 */
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end


