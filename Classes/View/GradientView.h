//
//  GradientView.h
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GradientView : UIView
{
@private
	CGFloat _startR;
	CGFloat _startG;
	CGFloat _startB;
	CGFloat _startA;
	CGFloat _endR;
	CGFloat _endG;
	CGFloat _endB;
	CGFloat _endA;
}

- (void)gradientFrom:(UIColor *)from to:(UIColor *)to;

@property (nonatomic) BOOL centerGradient;

@end
