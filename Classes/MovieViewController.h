//
//  MovieViewController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Movie.h"

@interface MovieViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UITextFieldDelegate>
{
	UITextView *myTextView;
	Movie *_movie;
}

+ (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title;
+ (MovieViewController *)withMovie: (Movie *) newMovie;

@property (nonatomic, retain) Movie *movie;

@end
