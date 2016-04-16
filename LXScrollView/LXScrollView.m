//
//  LXScrollView.m
//  ScrollViewDemo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 千行时线. All rights reserved.
//

#import "LXScrollView.h"

typedef NS_ENUM(NSUInteger, LXPosition) {
    LXPositionLeft,
    LXPositionCenter,
    LXPositionRight,
};

static void *const kKVOContext = (void *const)&kKVOContext;

@interface LXScrollView ()
{
    UIImageView *_leftImageView;
    UIImageView *_rightImageView;
    UIImageView *_centerImageView;

    NSTimer *_timer;
    BOOL _enableTimer;

    NSInteger _indexes[3];
    void (^_pageControlConfiguration)(NSUInteger currentPage);
    void (^_imageViewConfiguration)(UIImageView *imageView, NSUInteger index);
    void (^_imageViewDidTapNotifyBlock)(UIImageView *imageView, NSUInteger index);
}
@end

@implementation LXScrollView

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentOffset" context:kKVOContext];
}

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.bounces = NO;
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;

    [self.panGestureRecognizer addTarget:self action:@selector(panGestureRecognizerAction:)];
    [self addObserver:self forKeyPath:@"contentOffset" options:kNilOptions context:kKVOContext];

    UIImageView * __strong *imageViews[] = { &_leftImageView, &_centerImageView, &_rightImageView };
    for (int i = 0; i < 3; ++i) {
        UIImageView *imageView = [UIImageView new];
        [self addSubview:imageView];
        *(imageViews[i]) = imageView;

        imageView.userInteractionEnabled = YES;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;

        [imageView addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(imageViewTapGestureRecognizerAction:)]];
    }

    NSDictionary *views =
    NSDictionaryOfVariableBindings(_leftImageView, _centerImageView, _rightImageView, self);
    NSString *visualFormats[] = {
        @"V:|[_centerImageView(self)]|",
        @"H:|[_leftImageView(self)][_centerImageView(self)][_rightImageView(self)]|" };
    NSLayoutFormatOptions options = NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom;
    for (int i = 0; i < 2; ++i) {
        [self addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:visualFormats[i]
                                                 options:options
                                                 metrics:nil
                                                   views:views]];
    }
}

#pragma mark - 点击处理

- (void)imageViewTapGestureRecognizerAction:(UITapGestureRecognizer *)tapGR
{
    if (self.contentOffset.x != self.bounds.size.width) {
        return;
    }
    
    if (_imageViewDidTapNotifyBlock) {
        _imageViewDidTapNotifyBlock((UIImageView *)tapGR.view, _indexes[LXPositionCenter]);
    }
}

#pragma mark - 循环滚动处理

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != kKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    CGFloat contentOffsetX = self.contentOffset.x;
    CGFloat scrollViewWidth = self.bounds.size.width;

    if (contentOffsetX <= 0 || contentOffsetX >= 2 * scrollViewWidth) {

        self.contentOffset = (CGPoint){ .x = scrollViewWidth };

        if (!_imageViewConfiguration) {
            return;
        }

        if (contentOffsetX <= 0) {

            _indexes[LXPositionRight] = _indexes[LXPositionCenter];
            _imageViewConfiguration(_rightImageView, _indexes[LXPositionRight]);

            _indexes[LXPositionCenter] = _indexes[LXPositionLeft];
            _imageViewConfiguration(_centerImageView, _indexes[LXPositionCenter]);

            if (--_indexes[LXPositionLeft] < 0) {
                _indexes[LXPositionLeft] = _numberOfPages - 1;
            }
            _imageViewConfiguration(_leftImageView, _indexes[LXPositionLeft]);

            !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[LXPositionCenter]);

        } else {

            _indexes[LXPositionLeft] = _indexes[LXPositionCenter];
            _imageViewConfiguration(_leftImageView, _indexes[LXPositionLeft]);

            _indexes[LXPositionCenter] = _indexes[LXPositionRight];
            _imageViewConfiguration(_centerImageView, _indexes[LXPositionCenter]);

            if (++_indexes[LXPositionRight] > _numberOfPages - 1) {
                _indexes[LXPositionRight] = 0;
            }
            _imageViewConfiguration(_rightImageView, _indexes[LXPositionRight]);

            !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[LXPositionCenter]);
        }
    }
}

#pragma mark - 拖拽手势处理

- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)panGR
{
    switch (panGR.state) {
        case UIGestureRecognizerStateBegan:
            if (_enableTimer) {
                [self _invalidateTimer];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (_enableTimer) {
                [self _startTimer];
            }
            break;
        default:
            break;
    }
}

#pragma mark - 定时器处理

- (void)startTimer
{
    _enableTimer = YES;

    [self _startTimer];
}

- (void)_startTimer
{
    [_timer invalidate];

    _timer = [NSTimer timerWithTimeInterval:_timeInterval
                                     target:self
                                   selector:@selector(timerFire)
                                   userInfo:nil
                                    repeats:YES];

    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer
{
    _enableTimer = NO;

    [self _invalidateTimer];
}

- (void)_invalidateTimer
{
    [_timer invalidate];

    _timer = nil;
}

- (void)timerFire
{
    [self setContentOffset:(CGPoint){ .x = self.bounds.size.width * 2 } animated:YES];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    newSuperview ?: [self _invalidateTimer];
}

#pragma mark - 配置内容

- (void)configureImageViewAtIndex:(void (^)(UIImageView * _Nonnull, NSUInteger))configuration
{
    _imageViewConfiguration = configuration;

    if (_numberOfPages >= 3) {

        self.scrollEnabled = YES;

        _indexes[LXPositionLeft] = 0;
        _imageViewConfiguration(_leftImageView, _indexes[LXPositionLeft]);

        _indexes[LXPositionCenter] = 1;
        _imageViewConfiguration(_centerImageView, _indexes[LXPositionCenter]);

        _indexes[LXPositionRight] = 2;
        _imageViewConfiguration(_rightImageView, _indexes[LXPositionRight]);

    } else if (_numberOfPages == 2) {

        self.scrollEnabled = YES;

        _indexes[LXPositionLeft] = 0;
        _imageViewConfiguration(_leftImageView, _indexes[LXPositionLeft]);

        _indexes[LXPositionCenter] = 1;
        _imageViewConfiguration(_centerImageView, _indexes[LXPositionCenter]);

    } else if (_numberOfPages == 1) {

        self.scrollEnabled = NO;

        _indexes[LXPositionLeft] = 0;
        _imageViewConfiguration(_leftImageView, _indexes[LXPositionLeft]);

    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"numberOfPages必须大于0"
                                     userInfo:nil];
    }

    if (self.contentSize.width == self.bounds.size.width * 3) {
        self.contentOffset = CGPointZero;
    }
}

- (void)configurePageControlForCurrentPage:(void (^)(NSUInteger))configuration
{
    _pageControlConfiguration = configuration;
}

- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(UIImageView * _Nonnull, NSUInteger))block
{
    _imageViewDidTapNotifyBlock = block;
}

@end
