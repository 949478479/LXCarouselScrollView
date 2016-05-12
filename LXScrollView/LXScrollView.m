//
//  LXScrollView.m
//  ScrollViewDemo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "LXScrollView.h"

@interface _LXMessageInterceptor : NSProxy
@property (nonatomic, weak) id receiver;
@property (nonatomic, unsafe_unretained) id middleMan;
@end

@implementation _LXMessageInterceptor

- (instancetype)initWithMiddleMan:(id)middleMan
{
    _middleMan = middleMan;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([_middleMan respondsToSelector:aSelector]) {
        return _middleMan;
    }
    if ([_receiver respondsToSelector:aSelector]) {
        return _receiver;
    }
    return nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([_middleMan respondsToSelector:aSelector]) {
        return YES;
    }
    if ([_receiver respondsToSelector:aSelector]) {
        return YES;
    }
    return NO;
}

@end

typedef NS_ENUM(NSUInteger, _LXPosition) {
    _LXPositionLeft,
    _LXPositionCenter,
    _LXPositionRight,
};

static char kKVOContext;

@interface LXScrollView ()
{
    NSTimer *_timer;
    BOOL _enableTimer;

    BOOL _isScrolling;
    BOOL _isPreparingForReloadData;
    BOOL _shouldReloadDataAfterScrolling;

    UIImageView *_leftImageView;
    UIImageView *_rightImageView;
    UIImageView *_centerImageView;

    _LXMessageInterceptor *_messageInterceptor;

    NSInteger _indexes[3];
    void (^_pageControlConfiguration)(NSUInteger currentPage);
    void (^_imageViewConfiguration)(UIImageView *imageView, NSUInteger index);
    void (^_imageViewDidTapNotifyBlock)(UIImageView *imageView, NSUInteger index);
}
@end

@implementation LXScrollView

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentOffset" context:&kKVOContext];
}

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

    // 使其成为自己的代理，拦截部分代理方法
    _messageInterceptor = [[_LXMessageInterceptor alloc] initWithMiddleMan:self];
    [super setDelegate:(id<UIScrollViewDelegate>)_messageInterceptor];

    self.bounces = NO;
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;

    // 通过监听 contentOffset 来处理滚动
    [self addObserver:self forKeyPath:@"contentOffset" options:kNilOptions context:&kKVOContext];

    // 添加轻击手势
    [self addGestureRecognizer:
     [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)]];

    // 添加三个 imageView 作为子视图
    UIImageView * __strong *imageViews[] = { &_leftImageView, &_centerImageView, &_rightImageView };
    for (int i = 0; i < 3; ++i) {
        UIImageView *imageView = [UIImageView new];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        *(imageViews[i]) = imageView;
        [self addSubview:imageView];
    }

    // 为 imageView 设置约束，等宽等高，相邻排列
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

#pragma mark - 定时器处理

- (void)startTimer
{
    if (_numberOfPages < 2) {
        return;
    }

    _enableTimer = YES;

    [self _startTimer];
}

- (void)_startTimer
{
    if (!_enableTimer) {
        return;
    }

    [_timer invalidate];

    _timer = [NSTimer timerWithTimeInterval:_timeInterval
                                     target:self
                                   selector:@selector(_timerFire)
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

- (void)_timerFire
{
    _isScrolling = YES;
    self.userInteractionEnabled = NO;
    [self setContentOffset:(CGPoint){ .x = self.bounds.size.width * 2 } animated:YES];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    // 从父视图移除前废止定时器，打破引用循环
    newSuperview ?: [self _invalidateTimer];

    [super willMoveToSuperview:newSuperview];
}

#pragma mark - 代理方法转发

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
    _messageInterceptor.receiver = delegate;
}

- (id<UIScrollViewDelegate>)delegate
{
    return _messageInterceptor.receiver;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isScrolling = YES;
    [self _invalidateTimer];

    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isScrolling = NO;
    [self _startTimer];

    [self _reloadDataAfterScrollingIfNeeded];
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    _isScrolling = NO;
    self.userInteractionEnabled = YES;

    [self _reloadDataAfterScrollingIfNeeded];

    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

#pragma mark - 循环滚动处理

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != &kKVOContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }

    CGFloat scrollViewWidth = self.bounds.size.width;
    CGFloat contentSizeWidth = self.contentSize.width;

    // scrollView 及其子视图尚未布局完成
    if (scrollViewWidth == 0 || contentSizeWidth != scrollViewWidth * 3) {
        return;
    }

    CGFloat contentOffsetX = self.contentOffset.x;

    // 滚动到左边界或右边界
    if (contentOffsetX <= 0 || contentOffsetX >= 2 * scrollViewWidth) {

        // 重置回中心位置
        self.contentOffset = (CGPoint){ .x = scrollViewWidth };

        // 直接返回，否则可能会导致索引越界等问题
        if (_isPreparingForReloadData || !_imageViewConfiguration) {
            return;
        }

        // 将图片内容左移或右移一个位置
        if (contentOffsetX <= 0) {

            _indexes[_LXPositionRight] = _indexes[_LXPositionCenter];
            _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);

            _indexes[_LXPositionCenter] = _indexes[_LXPositionLeft];
            _imageViewConfiguration(_centerImageView, _indexes[_LXPositionCenter]);

            if (--_indexes[_LXPositionLeft] < 0) {
                _indexes[_LXPositionLeft] = _numberOfPages - 1;
            }
            _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

            !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[_LXPositionCenter]);

        } else {

            _indexes[_LXPositionLeft] = _indexes[_LXPositionCenter];
            _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

            _indexes[_LXPositionCenter] = _indexes[_LXPositionRight];
            _imageViewConfiguration(_centerImageView, _indexes[_LXPositionCenter]);

            if (++_indexes[_LXPositionRight] > _numberOfPages - 1) {
                _indexes[_LXPositionRight] = 0;
            }
            _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);
            
            !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[_LXPositionCenter]);
        }
    }
}

#pragma mark - 图片点击处理

- (void)_handleTap:(UITapGestureRecognizer *)tapGR
{
    // 在中间停稳时才响应点击
    if (self.contentOffset.x != self.bounds.size.width) {
        return;
    }

    if (_imageViewDidTapNotifyBlock) {
        _imageViewDidTapNotifyBlock(_centerImageView, _indexes[_LXPositionCenter]);
    }
}

#pragma mark - 刷新内容

- (void)prepareForReloadData
{
    [self invalidateTimer];

    _isPreparingForReloadData = YES;
}

- (void)reloadData
{
    // 如果处于滚动中，则需滚动结束后再刷新
    if (_isScrolling) {
        _shouldReloadDataAfterScrolling = YES;
        return;
    }

    // 将 scrollView 重置回中间位置
    CGFloat scrollViewWidth = self.bounds.size.width;
    if (self.contentSize.width != scrollViewWidth * 3) {
        [self layoutIfNeeded];
        self.contentOffset = (CGPoint){ .x = self.bounds.size.width };
    } else {
        self.contentOffset = (CGPoint){ .x = scrollViewWidth };
    }

    if (_numberOfPages >= 3) {

        self.scrollEnabled = YES;

        _indexes[_LXPositionLeft] = _numberOfPages - 1;
        _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

        _indexes[_LXPositionCenter] = 0;
        _imageViewConfiguration(_centerImageView, _indexes[_LXPositionCenter]);

        _indexes[_LXPositionRight] = 1;
        _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);

    } else if (_numberOfPages == 2) {

        self.scrollEnabled = YES;

        _indexes[_LXPositionLeft] = 1;
        _imageViewConfiguration(_leftImageView, _indexes[_LXPositionLeft]);

        _indexes[_LXPositionCenter] = 0;
        _imageViewConfiguration(_centerImageView, _indexes[_LXPositionCenter]);

        _indexes[_LXPositionRight] = 1;
        _imageViewConfiguration(_rightImageView, _indexes[_LXPositionRight]);

    } else if (_numberOfPages == 1) {

        self.scrollEnabled = NO;

        _indexes[_LXPositionCenter] = 0;
        _indexes[_LXPositionLeft] = NSNotFound;
        _indexes[_LXPositionRight] = NSNotFound;

        _leftImageView.image = nil;
        _rightImageView.image = nil;
        _imageViewConfiguration(_centerImageView, _indexes[_LXPositionCenter]);

    } else {

        self.scrollEnabled = NO;

        _leftImageView.image = nil;
        _rightImageView.image = nil;
        _centerImageView.image = nil;

        _indexes[_LXPositionLeft] = NSNotFound;
        _indexes[_LXPositionRight] = NSNotFound;
        _indexes[_LXPositionCenter] = NSNotFound;
    }

    !_pageControlConfiguration ?: _pageControlConfiguration(_indexes[_LXPositionCenter]);

    _isPreparingForReloadData = NO;
}

- (void)_reloadDataAfterScrollingIfNeeded
{
    if (_shouldReloadDataAfterScrolling) {
        _shouldReloadDataAfterScrolling = NO;
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
