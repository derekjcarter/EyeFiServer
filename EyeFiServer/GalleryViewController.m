//
//  GalleryViewController.m
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import "GalleryViewController.h"
#import "GalleryCellView.h"


static NSString *kCellIdentifier = @"cellID";       // UICollectionViewCell storyboard id
static float galleryTopMargin = 20.0f;              // top margin for uicollectionview
static float gallerySideMargins = 10.0f;            // side margins for uicollectionview
static float galleryBottomMargin = 0.0f;            // bottom margin for uicollectionview
static float galleryMinSpacing = 5.0f;              // minimum spacing between photos


@interface GalleryViewController ()
{
    // Info button
    UIButton                      *_infoButton;
    
    // Gallery collection view
    UICollectionView              *_collectionView;
    UICollectionViewFlowLayout    *_flowLayout;
    NSIndexPath                   *_currentTouchedIndexPath;
    
    // Async queue for thumbnail images
    dispatch_queue_t              thumbnailLoadingQueue;
    
    // Loading view
    UIView                        *_loadingView;
    UIActivityIndicatorView       *_spinningIndicator;
    BOOL                          _loaderIsShown;
}
@end

@implementation GalleryViewController

- (id)init
{
    //NSLog(@"GalleryViewController | init");
    if (self = [super init]) {
        thumbnailLoadingQueue = dispatch_queue_create("com.derek.thumbnailloadingqueue", NULL);
        
        // Initalize Eye-Fi server with upload key (key can be found at "~/Library/Eye-Fi/Settings.xml")
        _eyefiServer = [[EyeFiServer alloc] initWithUploadKey:@"e5c081920d6f9d6987c50569c563a3b4"];
        [_eyefiServer startServer];
    }
    return self;
}

- (void)viewDidLoad
{
    //NSLog(@"GalleryViewController | viewDidLoad");
    [super viewDidLoad];
    
	// Hide navigation bar
    self.navigationController.navigationBarHidden = YES;
    
    // Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationShouldBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingPhoto:) name:EyeFiNotificationIncomingPhoto object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGallery:) name:EyeFiNotificationUnarchiveComplete object:nil];
    
    // Create the assets array of photos already saved
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.datasource = [[NSMutableArray array] init];
    
    // Load in the assets from the documents directory
    NSArray *dirContents = [[NSBundle bundleWithPath:[paths objectAtIndex:0]] pathsForResourcesOfType:@".JPG" inDirectory:nil];
    NSEnumerator *reverseEnumerator = [dirContents reverseObjectEnumerator];
    for (id object in reverseEnumerator) {
        [self.datasource addObject:object];
    }
    //NSLog(@"self.datasource: %@", self.datasource);
    
    // Configure collection view layout
    _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [_flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    // Set up collection view
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:_flowLayout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    [_collectionView setBackgroundColor:[UIColor clearColor]];
    _collectionView.alwaysBounceVertical = YES;
    
    // Register cell identifier
    [_collectionView registerClass:[GalleryCellView class] forCellWithReuseIdentifier:kCellIdentifier];
    
    // Add collection view to uiview
    [self.view addSubview:_collectionView];
    
    // Add long press gesture for deletion
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    longPressGesture.minimumPressDuration = .2;
    longPressGesture.delegate = self;
    [_collectionView addGestureRecognizer:longPressGesture];
    
    // Set up info button
    _infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [_infoButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchDown];
    [_infoButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpInside];
    [_infoButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchUpOutside];
    [self.view addSubview:_infoButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews
{
    // Reset the collectionview frame
    float offset = (gallerySideMargins * 2) + 5.0f;
	_collectionView.frame = CGRectMake(0, -offset, self.view.bounds.size.width, self.view.bounds.size.height+offset);
    
    // Set infoButton button frame
    _infoButton.frame = CGRectMake(5, self.view.bounds.size.height-40, 35, 35);
    
    if (_loaderIsShown) {
        _loadingView.center = self.view.center;
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    // Update collectionview
    [_collectionView performBatchUpdates:nil completion:nil];
}

- (void)applicationShouldBecomeActive
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EyeFiNotificationIncomingPhoto object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EyeFiNotificationUnarchiveComplete object:nil];
}



#pragma mark - UIButton Press/Release Methods
/***************************************************************************************************************
 * UIButton Press/Release Methods
 ***************************************************************************************************************/
- (void)buttonPress:(UIButton*)button
{
    // Animate button
    button.transform = CGAffineTransformMakeScale(1,1);
    [UIView beginAnimations:@"button" context:nil];
    [UIView setAnimationDuration:0.3];
    button.transform = CGAffineTransformMakeScale(1.2,1.2);
    [UIView commitAnimations];
    
}

- (void)buttonRelease:(UIButton*)button
{
    // Animate button
    [UIView beginAnimations:@"button" context:nil];
    [UIView setAnimationDuration:0.3];
    button.transform = CGAffineTransformMakeScale(1,1);
    [UIView commitAnimations];
    
    // Show alert with Eye-Fi Upload Key entry
    UIAlertView *confirmAlertView = [[UIAlertView alloc] init];
    [confirmAlertView setTitle:@"Connected to your EyeFi?"];
    [confirmAlertView setMessage:@"You must be connected to the same Wi-Fi network as your EyeFi card for photos to be transferred."];
    [confirmAlertView addButtonWithTitle:@"OK"];
    [confirmAlertView setDelegate:self];
    confirmAlertView.tag = 1;
    confirmAlertView.alertViewStyle = UIAlertViewStyleDefault;
    CGAffineTransform moveUp = CGAffineTransformMakeTranslation(0.0, 0.0);
    [confirmAlertView setTransform: moveUp];
    [confirmAlertView show];
}



#pragma mark - UICollectionViewDataSource Methods
/***************************************************************************************************************
 * UICollectionViewDataSource Methods
 ***************************************************************************************************************/
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.datasource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Custom cell
    GalleryCellView *cell = (GalleryCellView *)[collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    // Clear image for cell to reload later
	cell.alpha = 0.0;
	cell.imageView.image = nil;
    
    // Load in the image to the cell
    dispatch_async(thumbnailLoadingQueue, ^{
        // File image
        UIImage *image = [UIImage imageWithContentsOfFile:self.datasource[indexPath.row]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = image;
            cell.fileName.text = self.datasource[indexPath.row];
            
            [UIView animateWithDuration: 0.5
                                  delay: 0.0
                                options: 0
                             animations:^(void) {
                                 cell.alpha = 1.0;
                             }
                             completion:^(BOOL finished){
                                 
                             }];
        });
    });
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
{
	UICollectionReusableView *reusableView = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
	return reusableView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
}



#pragma mark - UICollectionView Layout Methods
/***************************************************************************************************************
 * UICollectionView Layout Methods
 ***************************************************************************************************************/
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return CGSizeMake(370, 370); // portrait - 2 across (generic ratios)
    } else {
        return CGSizeMake(320, 320); // landscape - 3 across (generic ratios)
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(galleryTopMargin, gallerySideMargins, galleryBottomMargin, gallerySideMargins);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return galleryMinSpacing;
}



#pragma mark - Gallery Notification Methods
/***************************************************************************************************************
 * Gallery Notification Methods
 ***************************************************************************************************************/
- (void)updateGallery:(NSNotification *)notification
{
    NSLog(@"GalleryViewController | updateGallery : notification= %@", notification);
    
    dispatch_block_t updates = ^{
        // Path comes from the notification so append the path to the assets
        [self.datasource insertObject: [notification.userInfo objectForKey:@"path"] atIndex:0];
        
        [_collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]];
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Perform update to collection view
        if (_collectionView) {
            [_collectionView performBatchUpdates:updates completion:nil];
            
            // Notify the gallery has been updated
            [[NSNotificationCenter defaultCenter] postNotificationName:EyeFiNotificationCommunication object:nil userInfo:[NSDictionary dictionaryWithObject:@"GalleryUpdated" forKey:@"method"]];
        }
        
        [self removeLoader];
    });
}

- (void)incomingPhoto:(NSNotification *)notification
{
    NSLog(@"GalleryViewController | incomingPhoto : notification= %@", notification);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoader];
    });
}



#pragma mark - Loader View Methods
/***************************************************************************************************************
 * Loader View Methods
 ***********************************************q****************************************************************/
- (void)showLoader
{
    if (!_loaderIsShown) {
        _loaderIsShown = YES;
        
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
        _loadingView.opaque = NO;
		_loadingView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8];
		UIBezierPath *menuRounded = [UIBezierPath bezierPathWithRoundedRect: _loadingView.bounds
                                                          byRoundingCorners: UIRectCornerAllCorners
                                                                cornerRadii: CGSizeMake(15.0, 15.0)];
		CAShapeLayer *menuShape = [[CAShapeLayer alloc] init];
		[menuShape setPath:menuRounded.CGPath];
		_loadingView.layer.mask = menuShape;
        
        _spinningIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        _spinningIndicator.frame = CGRectMake(0, 0, 75, 75);
        [_spinningIndicator startAnimating];
        [_loadingView addSubview:_spinningIndicator];
        
        [self.view addSubview:_loadingView];
        [_loadingView resignFirstResponder];
    }
}

- (void)removeLoader
{
    [_spinningIndicator removeFromSuperview];
    [_loadingView removeFromSuperview];
    
    _loaderIsShown = NO;
}



#pragma mark - Remove Photo Methods
/***************************************************************************************************************
 * Remove Photo Methods
 ***********************************************q****************************************************************/
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan && gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gestureRecognizer locationInView:_collectionView];
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:touchPoint];
        if (indexPath) {
            _currentTouchedIndexPath = indexPath;
            
            GalleryCellView *cell = (GalleryCellView *)[_collectionView cellForItemAtIndexPath:indexPath];
            cell.alpha = 0.25f;
        }
    }

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint touchPoint = [gestureRecognizer locationInView:_collectionView];
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:touchPoint];
        if (indexPath && indexPath == _currentTouchedIndexPath) {
            GalleryCellView *cell = (GalleryCellView *)[_collectionView cellForItemAtIndexPath:indexPath];
            cell.alpha = 0.33f;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Remove this photo?"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Remove",
                                      nil];
            [alertView show];
        } else {
            if (_currentTouchedIndexPath) {
                // Reset cell
                GalleryCellView *cell = (GalleryCellView *)[_collectionView cellForItemAtIndexPath:_currentTouchedIndexPath];
                cell.alpha = 1;
                _currentTouchedIndexPath = nil;
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Remove file
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filePath = [NSString stringWithFormat:@"%@", self.datasource[_currentTouchedIndexPath.row]];
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
        dispatch_block_t updates = ^{
            [self.datasource removeObjectAtIndex:_currentTouchedIndexPath.row];
            [_collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:_currentTouchedIndexPath.row inSection:0]]];
        };
        [_collectionView performBatchUpdates:updates completion:nil];
    } else {
        // Reset cell
        GalleryCellView *cell = (GalleryCellView *)[_collectionView cellForItemAtIndexPath:_currentTouchedIndexPath];
        cell.alpha = 1.0f;
    }
}

@end