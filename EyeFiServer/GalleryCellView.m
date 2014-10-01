//
//  GalleryCellView.m
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import "GalleryCellView.h"

@implementation GalleryCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.clipsToBounds = YES;
		self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:self.imageView];
        
        self.fileName = [[UILabel alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-40, self.bounds.size.width, 40)];
        self.fileName.font = [UIFont systemFontOfSize:12.0f];
        self.fileName.textColor = [UIColor whiteColor];
        self.fileName.numberOfLines = 0;
		[self.contentView addSubview:self.fileName];
    }
    return self;
}

- (void)layoutSubviews
{
    self.imageView.frame = self.bounds;
    self.fileName.frame = CGRectMake(0, self.bounds.size.height-50, self.bounds.size.width, 50);
}

@end
