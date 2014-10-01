//
//  GalleryViewController.h
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EyeFiServer.h"

@interface GalleryViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) EyeFiServer *eyefiServer;
@property (nonatomic, strong) NSMutableArray *datasource;

@end
