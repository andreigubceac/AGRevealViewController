//
//  AGRevealViewController.m
//
//  Created by Andrei Gubceac on 1/29/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "AGRevealViewController.h"

float kOffsetX = 60;
const CGFloat kSlideAnimationDuration = .3;

NSString *kAGRevealViewControllerWillRevealNotification = @"kAGRevealViewControllerWillRevealNotification", *kAGRevealViewControllerDidRevealNotification = @"kAGRevealViewControllerDidRevealNotification";
NSString *kAGRevealViewControllerWillCoverNotification = @"kAGRevealViewControllerWillCoverNotification", *kAGRevealViewControllerDidCoverNotification = @"kAGRevealViewControllerDidCoverNotification";

@interface AGRevealViewController () {
    UIView *_noUserInteractionView;
    UIButton *_leftItem, *_rightItem;
    UIScreenEdgePanGestureRecognizer *_leftEdgePanGestrue, *_rightEdgePanGesture;
}
@end

@implementation AGRevealViewController

- (id)initWithLeftViewController:(UIViewController*)leftViewController rightViewController:(UIViewController*)rightViewController centerViewController:(UIViewController*)centerViewController {
    if (self = [super init]) {
        _disableLeftReveal = _disableRightReveal = NO;
        _leftViewController     = leftViewController;
        _centerViewController   = centerViewController;
        _rightViewController    = rightViewController;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setLeftViewController:_leftViewController];
    [self setRightViewController:_rightViewController];
    [self setCenterViewController:_centerViewController];
    _leftViewController.view.hidden = _rightViewController.view.hidden = YES;
    
    _leftEdgePanGestrue = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    _leftEdgePanGestrue.edges = (UIRectEdgeLeft);
    [self.view addGestureRecognizer:_leftEdgePanGestrue];
    _rightEdgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    _rightEdgePanGesture.edges = (UIRectEdgeRight);
    [self.view addGestureRecognizer:_rightEdgePanGesture];
}

- (void)applyTransfromToDirection:(int)direction animated:(BOOL)animated completeBlock:(void(^)(void))block {
    void (^applyTransformBlock)(void) = ^{
        self.centerViewController.view.transform = CGAffineTransformMakeTranslation(direction * (CGRectGetWidth(self->_centerViewController.view.frame)-kOffsetX), 0);
        
        if ([self isLeftSideDisplayed]) {
            [self.view insertSubview:self.leftViewController.view aboveSubview:self.rightViewController.view];
        }
        else if ([self isRightSideDisplayed]) {
            [self.view insertSubview:self.rightViewController.view aboveSubview:self->_leftViewController.view];
        }
        
        if ([self->_leftItem respondsToSelector:@selector(setSelected:)])
            self->_leftItem.selected = NO;
        if ([self->_rightItem respondsToSelector:@selector(setSelected:)])
            self->_rightItem.selected = NO;
        if (direction != 0) {
            UIView *_centerView = nil;
            if ([self->_centerViewController isKindOfClass:[UINavigationController class]]) {
                _centerView = ((UINavigationController*)self->_centerViewController).topViewController.view;
                self->_leftItem   = (UIButton*)((UINavigationController*)self->_centerViewController).topViewController.navigationItem.leftBarButtonItem.customView;
                self->_rightItem  = (UIButton*)((UINavigationController*)self->_centerViewController).topViewController.navigationItem.rightBarButtonItem.customView;
            }
            else {
                _centerView = self->_centerViewController.view;
                self->_leftItem   = (UIButton*)self->_centerViewController.navigationItem.leftBarButtonItem.customView;
                self->_rightItem  = (UIButton*)self->_centerViewController.navigationItem.rightBarButtonItem.customView;
            }
            if ([self->_leftItem respondsToSelector:@selector(setSelected:)])
                self->_leftItem.selected = YES;
            if ([self->_rightItem respondsToSelector:@selector(setSelected:)])
                self->_rightItem.selected = YES;
            
            if (nil == self->_noUserInteractionView) {
                self->_noUserInteractionView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                [self->_centerViewController.view addSubview:self->_noUserInteractionView];
                [self->_noUserInteractionView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeAction:)]];
                [self.view removeGestureRecognizer:self->_leftEdgePanGestrue];
                [self->_noUserInteractionView addGestureRecognizer:self->_leftEdgePanGestrue];
                [self.view removeGestureRecognizer:self->_rightEdgePanGesture];
                [self->_noUserInteractionView addGestureRecognizer:self->_rightEdgePanGesture];
                if ([_centerView isKindOfClass:[UIScrollView class]])
                    [(UIScrollView*)_centerView setScrollEnabled:NO];
            }
        }
        else if (self->_noUserInteractionView) {
            if ([self->_noUserInteractionView.superview isKindOfClass:[UIScrollView class]])
                [(UIScrollView*)self->_noUserInteractionView.superview setScrollEnabled:YES];
            [self->_noUserInteractionView removeGestureRecognizer:self->_leftEdgePanGestrue];
            [self.view addGestureRecognizer:self->_leftEdgePanGestrue];
            [self->_noUserInteractionView removeGestureRecognizer:self->_rightEdgePanGesture];
            [self.view addGestureRecognizer:self->_rightEdgePanGesture];
            [self->_noUserInteractionView removeFromSuperview];
            self->_noUserInteractionView = nil;
        }
    };
    UIViewController *_workingViewController;
    
    if (direction != 0) {
        _workingViewController = (direction == 1 ? _leftViewController : _rightViewController);
        [[NSNotificationCenter defaultCenter] postNotificationName:kAGRevealViewControllerWillRevealNotification object:_workingViewController];
        [_workingViewController viewWillAppear:animated];
    }
    else {
        _workingViewController = ([self isLeftSideDisplayed] ? _leftViewController : ([self isRightSideDisplayed] ? _rightViewController : nil));
        [[NSNotificationCenter defaultCenter] postNotificationName:kAGRevealViewControllerWillCoverNotification object:_workingViewController];
        [_workingViewController  viewWillDisappear:animated];
    }
    
    _leftViewController.view.hidden = _rightViewController.view.hidden = NO;
    if (animated == NO) {
        applyTransformBlock();
        if (block)block();
        if (direction != 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAGRevealViewControllerWillCoverNotification object:nil];
            [(direction == 1 ? _leftViewController : _rightViewController) viewWillDisappear:animated];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAGRevealViewControllerDidCoverNotification object:nil];
            _leftViewController.view.hidden = _rightViewController.view.hidden = YES;
            [_centerViewController viewWillAppear:animated];
        }
    }
    else {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:kSlideAnimationDuration animations:applyTransformBlock completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
            if (block)
                block();
            if (direction != 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAGRevealViewControllerDidRevealNotification object:nil];
                [_workingViewController viewDidAppear:animated];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAGRevealViewControllerDidCoverNotification object:nil];
                self->_leftViewController.view.hidden = self->_rightViewController.view.hidden = YES;
                [_workingViewController viewDidDisappear:animated];
            }
        }];
    }
}

- (void)panGestureAction:(UIScreenEdgePanGestureRecognizer*)g {
    if (UIGestureRecognizerStateBegan == g.state) {
        self.view.userInteractionEnabled = NO;
    }
    else if (UIGestureRecognizerStateChanged == g.state) {
        CGPoint pt = [g translationInView:g.view];
        if (_noUserInteractionView.superview) {
            if ([self isLeftSideDisplayed]) {
                if (pt.x<0)
                    self->_centerViewController.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(self->_centerViewController.view.frame)-kOffsetX+pt.x, 0);
            }
            else if ([self isRightSideDisplayed])
            {
                if (pt.x>0)
                    self->_centerViewController.view.transform = CGAffineTransformMakeTranslation(-CGRectGetWidth(self->_centerViewController.view.frame)+kOffsetX+pt.x, 0);
            }
        }
        else {
            if (pt.x<0) {
                if (_rightViewController && !self.disableRightReveal) {
                    if (CGRectGetMaxX(self->_centerViewController.view.frame) + ( pt.x - self->_centerViewController.view.transform.tx) > CGRectGetMinX(_rightViewController.view.frame)) {
                        _rightViewController.view.hidden = NO;
                        [self.view insertSubview:_rightViewController.view aboveSubview:_leftViewController.view];
                        self->_centerViewController.view.transform = CGAffineTransformMakeTranslation(pt.x, 0);
                    }
                }
            }
            else if (pt.x>0) {
                if (_leftViewController && !self.disableLeftReveal) {
                    if (CGRectGetMinX(self->_centerViewController.view.frame) + (pt.x - self->_centerViewController.view.transform.tx) < CGRectGetMaxX(_leftViewController.view.frame)) {
                        _leftViewController.view.hidden = NO;
                        [self.view insertSubview:_leftViewController.view aboveSubview:_rightViewController.view];
                        self->_centerViewController.view.transform = CGAffineTransformMakeTranslation(pt.x, 0);
                    }
                }
            }
        }
    }
    else {
        self.view.userInteractionEnabled = YES;
        int d = 0;
        if ([self isLeftSideDisplayed]) {
            d = _centerViewController.view.transform.tx <= CGRectGetWidth(self.view.frame)/2?0:1;
        }
        else if ([self isRightSideDisplayed]) {
            d = _centerViewController.view.transform.tx >= -CGRectGetWidth(self.view.frame)/2?0:-1;
        }
        [self applyTransfromToDirection:d animated:YES completeBlock:nil];
    }
}

- (void)closeAction:(UITapGestureRecognizer*)g {
    if (UIGestureRecognizerStateEnded == g.state) {
        [self applyTransfromToDirection:0 animated:YES completeBlock:nil];
    }
}

- (BOOL)isLeftSideDisplayed {
    return (_centerViewController.view.transform.tx >= kOffsetX && _leftViewController != nil);
}

- (BOOL)isRightSideDisplayed {
    return (fabs(_centerViewController.view.transform.tx) >= kOffsetX && _rightViewController != nil);
}

- (BOOL)isCenterSideDisplayed {
    return (_centerViewController.view.transform.tx==0);
}

- (void)toggleLeftSide:(id)s {
    [self toggleLeftSideAnimated:YES completeBlock:nil];
}

- (void)toggleRightSide:(id)s {
    [self toggleRightSideAnimated:YES completeBlock:nil];
}
#pragma mark - public

- (void)setRightViewController:(UIViewController *)rightViewController_ {
    if (_rightViewController.view.superview) {
        [_rightViewController viewWillDisappear:NO];
        [_rightViewController.view removeFromSuperview];
        [_rightViewController viewDidDisappear:NO];
    }
    [_rightViewController removeFromParentViewController];
    _rightViewController = rightViewController_;
    if (nil == _rightViewController)
        return;
    
    [self.view insertSubview:_rightViewController.view atIndex:0];
    [self addChildViewController:_rightViewController];
    [_rightViewController.view setFrame:self.view.bounds];
    CGRect _frame = self.view.bounds;
    _frame.size.width -= kOffsetX;
    _frame.origin.x = kOffsetX;
    [_rightViewController.view setFrame:_frame];
}

- (void)setLeftViewController:(UIViewController *)leftViewController_ {
    if (_leftViewController.view.superview) {
        [_leftViewController viewWillDisappear:NO];
        [_leftViewController.view removeFromSuperview];
        [_leftViewController viewDidDisappear:NO];
    }
    [_leftViewController removeFromParentViewController];
    _leftViewController = leftViewController_;
    if (nil == _leftViewController)
        return;
    [self addChildViewController:_leftViewController];
    [self.view insertSubview:_leftViewController.view atIndex:0];
    CGRect _frame = self.view.bounds;
    _frame.size.width -= kOffsetX;
    [_leftViewController.view setFrame:_frame];
}

- (void)setCenterViewController:(UIViewController *)centerViewController_ {
    if (_centerViewController.view.superview) {
        [_centerViewController viewWillDisappear:NO];
        [_centerViewController.view removeFromSuperview];
        [_centerViewController viewDidDisappear:NO];
    }
    [_centerViewController removeFromParentViewController];
    _centerViewController = centerViewController_;
    NSAssert(_centerViewController!=nil, @"The front view Controller is NULL");
    [_centerViewController viewWillAppear:NO];
    [self.view addSubview:centerViewController_.view];
    [self addChildViewController:_centerViewController];
    [_centerViewController viewDidAppear:NO];
    [_centerViewController.view setFrame:self.view.bounds];
    _centerViewController.view.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:.5].CGColor;
    _centerViewController.view.layer.shadowOpacity = .5;
    UIBezierPath *_shadowPath = [UIBezierPath bezierPathWithRect:(CGRect){{-10,0},{CGRectGetWidth(_centerViewController.view.frame)+20,CGRectGetHeight(_centerViewController.view.frame)}}];
    _centerViewController.view.layer.shadowPath = _shadowPath.CGPath;
}

- (void)toggleLeftSideAnimated:(BOOL)animated completeBlock:(void(^)(void))block {
    if ([self isRightSideDisplayed])
        [self applyTransfromToDirection:0 animated:animated completeBlock:^{
            [self applyTransfromToDirection:1 animated:animated completeBlock:block];
        }];
    else if ([self isLeftSideDisplayed])
        [self applyTransfromToDirection:0 animated:animated completeBlock:block];
    else
        [self applyTransfromToDirection:1 animated:animated completeBlock:block];
}

- (void)toggleRightSideAnimated:(BOOL)animated completeBlock:(void(^)(void))block {
    if ([self isLeftSideDisplayed])
        [self applyTransfromToDirection:0 animated:animated completeBlock:^{
            [self applyTransfromToDirection:-1 animated:animated completeBlock:block];
        }];
    else if ([self isRightSideDisplayed])
        [self applyTransfromToDirection:0 animated:animated completeBlock:block];
    else
        [self applyTransfromToDirection:-1 animated:animated completeBlock:block];
}

- (void)closeLeftSideAnimated:(BOOL)animated completeBlock:(void(^)(void))block {
    if ([self isLeftSideDisplayed])
        [self applyTransfromToDirection:0 animated:animated completeBlock:block];
    else if (block)
        block();
}

- (void)closeRightSideAnimated:(BOOL)animated completeBlock:(void(^)(void))block {
    if ([self isRightSideDisplayed])
        [self applyTransfromToDirection:0 animated:animated completeBlock:block];
    else if (block)
        block();
}

- (UIBarButtonItem*)leftItemWithButton:(UIButton*)button {
    UIBarButtonItem *_b = [[UIBarButtonItem alloc] initWithCustomView:button];
    [button addTarget:self action:@selector(toggleLeftSide:) forControlEvents:UIControlEventTouchUpInside];
    return _b;
}

- (UIBarButtonItem*)rightItemWithButton:(UIButton*)button {
    UIBarButtonItem *_b = [[UIBarButtonItem alloc] initWithCustomView:button];
    [button addTarget:self action:@selector(toggleRightSide:) forControlEvents:UIControlEventTouchUpInside];
    return _b;
}

@end
