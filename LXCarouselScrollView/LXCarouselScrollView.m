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

#pragma mark - 定时器相关

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
		if (!_timer || !_timer.isValid) {
			_timer = [NSTimer timerWithTimeInterval:_timeInterval
											 target:self
										   selector:@selector(_timerFire)
										   userInfo:nil
											repeats:YES];
			[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
		}
    }
}

- (void)_timerFire {
	[self _scrollToNextPageAnimated:YES];
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

#pragma mark - 滚动处理

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

- (void)_scrollToNextPageAnimated:(BOOL)animated
{
    if (!self.isTracking) {
        [self _beginScrolling];
        [self _disableInteraction];
        [self setContentOffset:(CGPoint){ .x = CGRectGetWidth(self.bounds) * 2 } animated:animated];
    }
}

- (void)_resetContentOffset {
    self.contentOffset = (CGPoint){ .x = CGRectGetWidth(self.bounds) };
}

- (void)_moveContentRight
{
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

- (void)_moveContentLeft
{
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

- (void)_handleScrollViewWillBeginDragging
{
	[self _beginScrolling];
	[self _invalidateTimer];
}

- (void)_handleScrollViewDidEndScrolling
{
	[self _endScrolling];
	[self _enableInteraction];
	[self _startTimerIfNeeded];
	[self _reloadAfterScrollingIfNeeded];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self _handleScrollViewWillBeginDragging];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        [self _disableInteraction];
    } else if ([self _isAtMiddlePosition]) {
		// 禁用交互性也会触发此方法，因此未必处于中间位置。
        [self _handleScrollViewDidEndScrolling];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	// 有时候滚动动画还在进行中，视图就从窗口移除了，此时滚动会停止并触发此方法，因此手动设置成终点位置。
	if (![self _isAtMiddlePosition]) {
		[self _scrollToNextPageAnimated:NO];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (![self _didCompleteLayout]) {
		return;
	}

    CGFloat contentOffsetX = self.contentOffset.x;
    CGFloat scrollViewWidth = CGRectGetWidth(self.bounds);

	// 满足该条件的情况为：1.滚动至两侧边界重置回中心位置；2.拖拽不足半页重置回中心位置。
	if (contentOffsetX == scrollViewWidth) {
		// 拖拽至正中间然后松手的情况会在 -scrollViewDidEndDragging:willDecelerate: 方法中处理。
		if (!scrollView.isTracking) {
			[self _handleScrollViewDidEndScrolling];
		}
	}
	// 滚动到左边界或右边界。
	else if (contentOffsetX <= 0 || contentOffsetX >= 2 * scrollViewWidth) {
		if (!_isInvalid && _imageViewConfiguration) {
			// 将图片内容左移或右移一个位置
			if (contentOffsetX <= 0) {
				[self _moveContentRight];
			} else {
				[self _moveContentLeft];
			}
		}
		// 防止无限拖拽，这里会直接触发 -scrollViewDidEndDragging:willDecelerate: 方法，且 decelerate 参数为 NO。
		if (scrollView.isTracking) {
			[self _disableInteraction];
		}
		[self _resetContentOffset];
	}
}

#pragma mark - 点击处理

- (void)setDisableTapAction:(BOOL)disableTapAction
{
    _disableTapAction = disableTapAction;
    _tapGestureRecognizer.enabled = !disableTapAction;
}

- (void)_handleTapAction:(UITapGestureRecognizer *)tapGR
{
    if (_middleImageView.image && [self _isAtMiddlePosition]) {
        if (_imageViewDidTapNotifyBlock) {
            _imageViewDidTapNotifyBlock(_middleImageView, _indexes[_LXPositionMiddle]);
        }
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
		[self _configureWhenPageCountMoreThanOrEqualThree];
    } else if (_numberOfPages == 2) {
		[self _configureWhenPageCountEqualTwo];
    } else if (_numberOfPages == 1) {
		[self _configureWhenPageCountEqualOne];
    } else {
		[self _configureWhenPageCountEqualZero];
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

- (void)_configureWhenPageCountMoreThanOrEqualThree
{
	self.scrollEnabled = YES;

	_indexes[_LXPositionLeft] = _numberOfPages - 1;
	_imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

	_indexes[_LXPositionMiddle] = 0;
	_imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);

	_indexes[_LXPositionRight] = 1;
	_imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);
}

- (void)_configureWhenPageCountEqualTwo
{
	self.scrollEnabled = YES;

	_indexes[_LXPositionLeft] = 1;
	_imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

	_indexes[_LXPositionMiddle] = 0;
	_imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);

	_indexes[_LXPositionRight] = 1;
	_imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);
}

- (void)_configureWhenPageCountEqualOne
{
	self.scrollEnabled = NO;

	_indexes[_LXPositionLeft] = NSNotFound;
	_indexes[_LXPositionMiddle] = 0;
	_indexes[_LXPositionRight] = NSNotFound;

	_leftImageView.image = nil;
	_rightImageView.image = nil;
	_imageViewConfiguration(_middleImageView, _indexes[_LXPositionMiddle]);
}

- (void)_configureWhenPageCountEqualZero
{
	self.scrollEnabled = NO;

	_leftImageView.image = nil;
	_rightImageView.image = nil;
	_middleImageView.image = nil;

	_indexes[_LXPositionLeft] = NSNotFound;
	_indexes[_LXPositionRight] = NSNotFound;
	_indexes[_LXPositionMiddle] = NSNotFound;
}

#pragma mark - 设置 block

- (void)configureImageViewAtIndex:(void (^)(UIImageView * _Nonnull, NSUInteger))configuration {
    _imageViewConfiguration = configuration;
}

- (void)configurePageControlForCurrentPage:(void (^)(NSUInteger))configuration {
    _pageControlConfiguration = configuration;
}

- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(UIImageView * _Nonnull, NSUInteger))block {
    _imageViewDidTapNotifyBlock = block;
}

@end
