//
//  LXCarouselScrollView.m
//  Demo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "LXCarouselScrollView.h"

typedef NS_ENUM(NSUInteger, _LXPosition) {
    _LXPositionLeft,
    _LXPositionMiddle,
    _LXPositionRight,
};

@interface LXCarouselScrollView () 
{
    NSTimer *_timer;
    BOOL _enableTimer;

    BOOL _isInvalid;
    BOOL _isScrolling;
    BOOL _delayReload;

    UIImageView *_leftImageView;
    UIImageView *_rightImageView;
    UIImageView *_middleImageView;

    UITapGestureRecognizer *_tapGestureRecognizer;

    NSInteger _indexes[3];
    void (^_pageControlConfiguration)(NSUInteger currentPage);
    void (^_imageViewConfiguration)(UIImageView *imageView, NSUInteger index);
    void (^_imageViewDidTapNotifyBlock)(UIImageView *imageView, NSUInteger index);
}
@end

@implementation LXCarouselScrollView

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit
{
    _timeInterval = 2;

    self.bounces = NO;
    self.delegate = self;
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;

    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapAction:)];
    [self addGestureRecognizer:_tapGestureRecognizer = tapGR];

    // 添加三个 imageView 作为子视图
    UIImageView *__strong *imageViews[] = { &_leftImageView, &_middleImageView, &_rightImageView };
    for (int i = 0; i < 3; ++i) {
        UIImageView *imageView = [UIImageView new];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        *(imageViews[i]) = imageView;
        [self addSubview:imageView];
    }

    // 为 imageView 设置约束，等宽等高，相邻排列
    NSDictionary *views = NSDictionaryOfVariableBindings(_leftImageView, _middleImageView, _rightImageView, self);
    NSString *visualFormats[] = {
        @"V:|[_middleImageView(self)]|",
        @"H:|[_leftImageView(self)][_middleImageView(self)][_rightImageView(self)]|"
    };
    NSLayoutFormatOptions options = NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom;
    NSMutableArray *constraints = [NSMutableArray new];
    for (int i = 0; i < 2; ++i) {
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:visualFormats[i]
                                                 options:options
                                                 metrics:nil
                                                   views:views]];
    }
    [NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - 辅助方法

- (BOOL)_isAtMiddlePosition {
    return self.contentOffset.x == CGRectGetWidth(self.bounds);
}

- (BOOL)_didCompleteLayout
{
    CGFloat contentSizeWidth = self.contentSize.width;
    CGFloat scrollViewWidth = CGRectGetWidth(self.bounds);
    return (scrollViewWidth != 0) && (scrollViewWidth * 3 == contentSizeWidth);
}

#pragma mark - 定时器处理

- (void)startTimer
{
    if (_numberOfPages > 1) {
        _enableTimer = YES;
        [self _startTimerIfNeeded];
    }
}

- (void)_startTimerIfNeeded
{
    if (_enableTimer) {
        [_timer invalidate];
        _timer = [NSTimer timerWithTimeInterval:_timeInterval
                                         target:self
                                       selector:@selector(_scrollToNextPageAnimated)
                                       userInfo:nil
                                        repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopTimer
{
    _enableTimer = NO;
    [self _invalidateTimer];
}

- (void)_invalidateTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    // 从父视图移除前废止定时器，打破引用循环
    newSuperview ?: [self _invalidateTimer];
    [super willMoveToSuperview:newSuperview];
}

#pragma mark - 滚动控制

- (void)_beginScrolling {
    _isScrolling = YES;
}

- (void)_endScrolling {
    _isScrolling = NO;
}

- (void)_disableInteraction
{
    self.userInteractionEnabled = NO;
    self.panGestureRecognizer.enabled = NO;
    _tapGestureRecognizer.enabled = NO;
}

- (void)_enableInteraction
{
    self.userInteractionEnabled = YES;
    self.panGestureRecognizer.enabled = YES;
    _tapGestureRecognizer.enabled = !self.disableTapAction;
}

- (void)_scrollToNextPageAnimated
{
    if (!self.isTracking) {
        [self _beginScrolling];
        [self _disableInteraction];
        [self setContentOffset:(CGPoint){ .x = CGRectGetWidth(self.bounds) * 2 } animated:YES];
    }
}

- (void)_resetContentOffset {
    self.contentOffset = (CGPoint){ .x = CGRectGetWidth(self.bounds) };
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self _beginScrolling];
    [self _invalidateTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        [self _disableInteraction];
    } else {
        [self _endScrolling];
        [self _startTimerIfNeeded];
        [self _reloadAfterScrollingIfNeeded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _endScrolling];
    [self _enableInteraction];
    [self _startTimerIfNeeded];
    [self _reloadAfterScrollingIfNeeded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self _endScrolling];
    [self _enableInteraction];
    [self _reloadAfterScrollingIfNeeded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![self _didCompleteLayout]) {
        return;
    }

    CGFloat contentOffsetX = self.contentOffset.x;
    CGFloat scrollViewWidth = CGRectGetWidth(self.bounds);

    // 滚动到左边界或右边界
    if (contentOffsetX <= 0 || contentOffsetX >= 2 * scrollViewWidth) {
        // 防止无限拖拽
        [self _disableInteraction];
        [self _resetContentOffset];

        // 直接返回，因为数据源已经无效，可能会导致索引越界等问题
        if (_isInvalid || !_imageViewConfiguration) {
            return;
        }

        // 将图片内容左移或右移一个位置
        if (contentOffsetX <= 0) {
            _indexes[_LXPositionRight] = _indexes[_LXPositionMiddle];
            _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);

            _indexes[_LXPositionMiddle] = _indexes[_LXPositionLeft];
            _imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);

            if (--_indexes[_LXPositionLeft] < 0) {
                _indexes[_LXPositionLeft] = _numberOfPages - 1;
            }
            _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

            !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[_LXPositionMiddle]);
        }
        else {
            _indexes[_LXPositionLeft] = _indexes[_LXPositionMiddle];
            _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

            _indexes[_LXPositionMiddle] = _indexes[_LXPositionRight];
            _imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);

            if (++_indexes[_LXPositionRight] > _numberOfPages - 1) {
                _indexes[_LXPositionRight] = 0;
            }
            _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);
            
            !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[_LXPositionMiddle]);
        }
    }
}

#pragma mark - 图片点击处理

- (void)setDisableTapAction:(BOOL)disableTapAction
{
    _disableTapAction = disableTapAction;
    _tapGestureRecognizer.enabled = !disableTapAction;
}

- (void)_handleTapAction:(UITapGestureRecognizer *)tapGR
{
    if (_imageViewDidTapNotifyBlock) {
        _imageViewDidTapNotifyBlock(_middleImageView, _indexes[_LXPositionMiddle]);
    }
}

#pragma mark - 刷新内容

- (void)invalidate
{
    _isInvalid = YES;
    [self _invalidateTimer];
}

- (void)reloadData
{
    // 如果处于滚动中，则需滚动结束后再刷新
    if (_isScrolling) {
        _delayReload = YES;
        return;
    }

    // 将 scrollView 重置回中间位置
    if ([self _didCompleteLayout]) {
        [self _resetContentOffset];
    } else {
        [self setNeedsLayout];
        [self layoutIfNeeded];
        [self _resetContentOffset];
    }

    if (_numberOfPages >= 3) {
        self.scrollEnabled = YES;

        _indexes[_LXPositionLeft] = _numberOfPages - 1;
        _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

        _indexes[_LXPositionMiddle] = 0;
        _imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);

        _indexes[_LXPositionRight] = 1;
        _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);
    }
    else if (_numberOfPages == 2) {
        self.scrollEnabled = YES;

        _indexes[_LXPositionLeft] = 1;
        _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

        _indexes[_LXPositionMiddle] = 0;
        _imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);

        _indexes[_LXPositionRight] = 1;
        _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);
    }
    else if (_numberOfPages == 1) {
        self.scrollEnabled = NO;

        _indexes[_LXPositionLeft] = NSNotFound;
        _indexes[_LXPositionMiddle] = 0;
        _indexes[_LXPositionRight] = NSNotFound;

        _leftImageView.image = nil;
        _rightImageView.image = nil;
        _imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);
    }
    else {
        self.scrollEnabled = NO;

        _leftImageView.image = nil;
        _rightImageView.image = nil;
        _middleImageView.image = nil;

        _indexes[_LXPositionLeft] = NSNotFound;
        _indexes[_LXPositionRight] = NSNotFound;
        _indexes[_LXPositionMiddle] = NSNotFound;
    }

    !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[_LXPositionMiddle]);

    _isInvalid = NO;
}

- (void)_reloadAfterScrollingIfNeeded
{
    if (_delayReload) {
        _delayReload = NO;
        [self reloadData];
    }
}

#pragma mark - 配置内容

- (void)configureImageViewAtIndex:(void (^)(UIImageView * _Nonnull, NSUInteger))configuration
{
    NSParameterAssert(configuration != nil);

    _imageViewConfiguration = configuration;
}

- (void)configurePageControlForCurrentPage:(void (^)(NSUInteger))configuration
{
    NSParameterAssert(configuration != nil);

    _pageControlConfiguration = configuration;
}

- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(UIImageView * _Nonnull, NSUInteger))block
{
    NSParameterAssert(block != nil);

    _imageViewDidTapNotifyBlock = block;
}

@end
