//
//  GalleryCellView.h
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryCellView : UICollectionViewCell

@property(nonatomic, strong, readwrite) UIImageView *imageView;
@property(nonatomic, strong, readwrite) UILabel *fileName;
@property(nonatomic, strong, readwrite) UIActivityIndicatorView *spinner;

@end