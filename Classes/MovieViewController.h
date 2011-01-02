//
//  MovieViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MovieProtocol.h"

/*!
 @brief Movie View.
 
 Display further information about a movie. Also allows to start playback if RemoteConnector
 supports it.
 */
@interface MovieViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													UISplitViewControllerDelegate>
{
@private
	UIPopoverController *popoverController;
	NSObject<MovieProtocol> *_movie; /*!< @brief Movie. */
	UITextView *_summaryView; /*!< @brief Summary of the movie. */
}

/*!
 @brief Open new view for given movie.
 
 @param newMovie Movie to open view for.
 @return MovieViewController instance.
 */
+ (MovieViewController *)withMovie: (NSObject<MovieProtocol> *) newMovie;



/*!
 @brief Movie.
 */
@property (nonatomic, retain) NSObject<MovieProtocol> *movie;

@end
