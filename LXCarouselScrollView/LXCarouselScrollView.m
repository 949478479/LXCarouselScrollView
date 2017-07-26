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
    _LXPositionCenter,
    _LXPositionRight,
};

@interface LXCarouselImageView ()
@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation LXCarouselImageView

- (UIActivityIndicatorView *)activityIndicator
{
	if (!_activityIndicator) {
		UIActivityIndicatorView *activityIndicator = [UIActivityIndicatorView new];
		activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:activityIndicator];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator
														 attribute:NSLayoutAttributeCenterX
														 relatedBy:NSLayoutRelationEqual
															toItem:self
														 attribute:NSLayoutAttributeCenterX
														multiplier:1.0
														  constant:0.0]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator
														 attribute:NSLayoutAttributeCenterY
														 relatedBy:NSLayoutRelationEqual
															toItem:self
														 attribute:NSLayoutAttributeCenterY
														multiplier:1.0
														  constant:0.0]];
		_activityIndicator = activityIndicator;
	}
	return _activityIndicator;
}

- (void)showActivityIndicator {
	[self.activityIndicator startAnimating];
}

- (void)hideActivityIndicator {
	[self.activityIndicator stopAnimating];
}

@end

@interface LXCarouselScrollView ()
{
    NSTimer *_timer;
    BOOL _enableTimer;

    BOOL _isInvalid;
    BOOL _isScrolling;
    BOOL _delayReload;

    LXCarouselImageView *_leftImageView;
    LXCarouselImageView *_rightImageView;
    LXCarouselImageView *_centerImageView;

    UITapGestureRecognizer *_tapGestureRecognizer;

    NSInteger _indexes[3];
    void (^_pageChangedBlock)(NSInteger currentPage);
    void (^_imageViewDidTapBlock)(LXCarouselImageView *imageView, NSInteger index);
    void (^_imageViewConfigurationBlock)(LXCarouselImageView *imageView, NSInteger index);
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
    LXCarouselImageView *__strong *imageViews[] = { &_leftImageView, &_centerImageView, &_rightImageView };
    for (int i = 0; i < 3; ++i) {
        LXCarouselImageView *imageView = [LXCarouselImageView new];
		imageView.clipsToBounds = YES;
		imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        *(imageViews[i]) = imageView;
        [self addSubview:imageView];
    }

    // 为 imageView 设置约束，等宽等高，相邻排列
    NSDictionary *views = NSDictionaryOfVariableBindings(_leftImageView, _centerImageView, _rightImageView, self);
    NSString *visualFormats[] = {
        @"V:|[_centerImageView(self)]|",
        @"H:|[_leftImageView(self)][_centerImageView(self)][_rightImageView(self)]|"
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

- (BOOL)_isAtCenterPosition {
    return self.contentOffset.x == CGRectGetWidth(self.bounds);
}

- (BOOL)_didCompleteLayout
{
    CGFloat contentSizeWidth = self.contentSize.width;
    CGFloat scrollViewWidth = CGRectGetWidth(self.bounds);
    return (scrollViewWidth != 0) && (scrollViewWidth * 3 == contentSizeWidth);
}

#pragma mark - 定时器

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

- (void)_scrollToCenterPosition {
    self.contentOffset = (CGPoint){ .x = CGRectGetWidth(self.bounds) };
}

- (void)_moveImageContentToRight
{
	_indexes[_LXPositionRight] = _indexes[_LXPositionCenter];
	_imageViewConfigurationBlock(_rightImageView, _indexes[_LXPositionRight]);

	_indexes[_LXPositionCenter] = _indexes[_LXPositionLeft];
	_imageViewConfigurationBlock(_centerImageView, _indexes[_LXPositionCenter]);

	if (--_indexes[_LXPositionLeft] < 0) {
		_indexes[_LXPositionLeft] = _numberOfPages - 1;
	}
	_imageViewConfigurationBlock(_leftImageView, _indexes[_LXPositionLeft]);

	!_pageChangedBlock ?: _pageChangedBlock(_indexes[_LXPositionCenter]);
}

- (void)_moveImageContentToLeft
{
	_indexes[_LXPositionLeft] = _indexes[_LXPositionCenter];
	_imageViewConfigurationBlock(_leftImageView, _indexes[_LXPositionLeft]);

	_indexes[_LXPositionCenter] = _indexes[_LXPositionRight];
	_imageViewConfigurationBlock(_centerImageView, _indexes[_LXPositionCenter]);

	if (++_indexes[_LXPositionRight] > _numberOfPages - 1) {
		_indexes[_LXPositionRight] = 0;
	}
	_imageViewConfigurationBlock(_rightImageView, _indexes[_LXPositionRight]);

	!_pageChangedBlock ?: _pageChangedBlock(_indexes[_LXPositionCenter]);
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
	[self _reloadDataIfNeeded];
	[self _startTimerIfNeeded];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self _handleScrollViewWillBeginDragging];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        [self _disableInteraction];
    }
	// 此为用户拖拽至中间位置松手的情况，禁用交互性也会触发此方法，因此需要判断是否处于中间位置。
	else if ([self _isAtCenterPosition]) {
        [self _handleScrollViewDidEndScrolling];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	// 若滚动动画尚未完成时视图就被从窗口移除，滚动会停止并触发此方法，因此手动设置滚动完成后的位置。
	if (![self _isAtCenterPosition]) {
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

	// 满足该条件的情况有两种：1.滚动至两侧边界重置回中心位置；2.拖拽不足半页重置回中心位置。
	if (contentOffsetX == scrollViewWidth) {
		// 此处为非用户拖拽的情况，用户拖拽至正中间然后松手的情况会在 -scrollViewDidEndDragging:willDecelerate: 方法中处理。
		if (!scrollView.isTracking) {
			[self _handleScrollViewDidEndScrolling];
		}
	}
	// 滚动到左边界或右边界。
	else if (contentOffsetX <= 0 || contentOffsetX >= 2 * scrollViewWidth) {
		if (!_isInvalid && _imageViewConfigurationBlock) {
			// 将图片内容左移或右移一个位置
			if (contentOffsetX <= 0) {
				[self _moveImageContentToRight];
			} else {
				[self _moveImageContentToLeft];
			}
		}
		// 防止多指交替不停地拖拽，这会触发 -scrollViewDidEndDragging:willDecelerate: 方法，且 decelerate 参数为 NO。
		if (scrollView.isTracking) {
			[self _disableInteraction];
		}
		[self _scrollToCenterPosition];
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
    if (_centerImageView.image && [self _isAtCenterPosition]) {
        if (_imageViewDidTapBlock) {
            _imageViewDidTapBlock(_centerImageView, _indexes[_LXPositionCenter]);
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
        [self _scrollToCenterPosition];
    } else {
        [self setNeedsLayout];
        [self layoutIfNeeded];
        [self _scrollToCenterPosition];
    }

    if (_numberOfPages >= 3) {
		[self _configureWhenPageCountMoreThanTwo];
    } else if (_numberOfPages == 2) {
		[self _configureWhenPageCountEqualTwo];
    } else if (_numberOfPages == 1) {
		[self _configureWhenPageCountEqualOne];
    } else {
		[self _configureWhenPageCountEqualZero];
    }

    !_pageChangedBlock ?: _pageChangedBlock(_indexes[_LXPositionCenter]);

    _isInvalid = NO;
}

- (void)_reloadDataIfNeeded
{
	if (_delayReload) {
		_delayReload = NO;
		[self reloadData];
	}
}

- (void)_configureWhenPageCountMoreThanTwo
{
	self.scrollEnabled = YES;

	_indexes[_LXPositionLeft] = _numberOfPages - 1;
	_imageViewConfigurationBlock(_leftImageView, _indexes[_LXPositionLeft]);

	_indexes[_LXPositionCenter] = 0;
	_imageViewConfigurationBlock(_centerImageView, _indexes[_LXPositionCenter]);

	_indexes[_LXPositionRight] = 1;
	_imageViewConfigurationBlock(_rightImageView, _indexes[_LXPositionRight]);
}

- (void)_configureWhenPageCountEqualTwo
{
	self.scrollEnabled = YES;

	_indexes[_LXPositionLeft] = 1;
	_imageViewConfigurationBlock(_leftImageView, _indexes[_LXPositionLeft]);

	_indexes[_LXPositionCenter] = 0;
	_imageViewConfigurationBlock(_centerImageView, _indexes[_LXPositionCenter]);

	_indexes[_LXPositionRight] = 1;
	_imageViewConfigurationBlock(_rightImageView, _indexes[_LXPositionRight]);
}

- (void)_configureWhenPageCountEqualOne
{
	self.scrollEnabled = NO;

	_indexes[_LXPositionLeft] = NSNotFound;
	_indexes[_LXPositionCenter] = 0;
	_indexes[_LXPositionRight] = NSNotFound;

	_leftImageView.image = nil;
	_rightImageView.image = nil;
	_imageViewConfigurationBlock(_centerImageView, _indexes[_LXPositionCenter]);
}

- (void)_configureWhenPageCountEqualZero
{
	self.scrollEnabled = NO;

	_leftImageView.image = nil;
	_rightImageView.image = nil;
	_centerImageView.image = nil;

	_indexes[_LXPositionLeft] = NSNotFound;
	_indexes[_LXPositionRight] = NSNotFound;
	_indexes[_LXPositionCenter] = NSNotFound;
}

#pragma mark - block

- (void)configureImageViewUsingBlock:(void (^)(LXCarouselImageView * _Nonnull, NSInteger))block {
    _imageViewConfigurationBlock = block;
}

- (void)notifyWhenPageDidChangeUsingBlock:(void (^)(NSInteger))block {
    _pageChangedBlock = block;
}

- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(LXCarouselImageView * _Nonnull, NSInteger))block {
    _imageViewDidTapBlock = block;
}

#pragma mark - 活动指示器

- (void)setActivityIndicatorViewColor:(UIColor *)color
{
	_leftImageView.activityIndicator.color = color;
	_centerImageView.activityIndicator.color = color;
	_rightImageView.activityIndicator.color = color;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)style
{
	_leftImageView.activityIndicator.activityIndicatorViewStyle = style;
	_centerImageView.activityIndicator.activityIndicatorViewStyle = style;
	_rightImageView.activityIndicator.activityIndicatorViewStyle = style;
}

@end
