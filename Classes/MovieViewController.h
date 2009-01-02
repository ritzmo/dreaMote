//
//  MovieViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MovieProtocol.h"

@interface MovieViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSObject<MovieProtocol> *_movie;
}

+ (MovieViewController *)withMovie: (NSObject<MovieProtocol> *) newMovie;

@property (nonatomic, retain) NSObject<MovieProtocol> *movie;

@end
