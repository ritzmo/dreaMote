//
//  RCButton.m
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "RCButton.h"

@interface RCButton()
@property (nonatomic, strong) NSString *backgroundFilename;
@end

@implementation RCButton

@synthesize backgroundFilename, rcCode;

/* Initialize */
- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		rcCode = -1;
	}
	return self;
}

- (void)setBackgroundFromFilename:(NSString *)filename
{
	if(filename)
	{
		UIImage *image = [UIImage imageNamed:filename];
		[self setBackgroundImage:image forState:UIControlStateHighlighted];
		[self setBackgroundImage:image forState:UIControlStateNormal];
	}
	self.backgroundFilename = filename;
}

- (NSString *)accessibilityLabel
{
	NSString *value = [super accessibilityLabel];
	if(backgroundFilename)
	{
		value = backgroundFilename;

		if([value hasPrefix:@"key_"])
			value = [value substringFromIndex:4];
		if([value hasSuffix:@".png"])
			value = [value substringToIndex:[value length]-4];

		// translate some filenames into more helpful texts ;)
		if([value isEqualToString:@"ff"])
			value = NSLocalizedString(@"Fast-Forward", @"Accessibility label for button: fast-forward");
		else if([value isEqualToString:@"fr"])
			value = NSLocalizedString(@"Fast-Rewind", @"Accessibility label for button: fast-rewind");
		else if([value isEqualToString:@"pp"])
			value = NSLocalizedString(@"Play-Pause", @"Accessibility label for button: play/pause");
		else if([value isEqualToString:@"rec"])
			value = NSLocalizedString(@"Record", @"Accessibility label for button: rec");
		else if([value isEqualToString:@"help_round"])
			value = @"help"; // to match the regular help button - maybe we should check for prefix help and replace it by localized version
		else if([value isEqualToString:@"leftarrow"])
			value = NSLocalizedString(@"Arrow (left)", @"Accessibility label for button: leftarrow");
		else if([value isEqualToString:@"rightarrow"])
			value = NSLocalizedString(@"Arrow (right)", @"Accessibility label for button: rightarrow");
	}
	return value;
}

@end
