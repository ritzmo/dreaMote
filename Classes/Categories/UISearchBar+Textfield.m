//
//  UISearchBar+Textfield.m
//  dreaMote
//
//  Created by Moritz Venn on 09.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "UISearchBar+Textfield.h"

@implementation UISearchBar(Textfield)

- (UITextField *)textField
{
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[UITextField class]])
			return (UITextField *)view;
	}
	return nil;
}

@end
