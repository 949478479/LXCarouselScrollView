//
//  LXScrollView.m
//  ScrollViewDemo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 千行时线. All rights reserved.
//

#import "LXScrollView.h"

@interface LXScrollView ()
{
    UIImageView *_leftImageView;
    UIImageView *_rightImageView;
    UIImageView *_centerImageView;
}
@end

@implementation LXScrollView

- (void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"contentOffset"
                 context:(__bridge void *)self];
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

    UIImageView * __strong *imageViews[] = { &_leftImageView, &_centerImageView, &_rightImageView };
    for (int i = 0; i < 3; ++i) {
        UIImageView *imageView = [UIImageView new];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:imageView];
        *(imageViews[i]) = imageView;
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

    [self addObserver:self
           forKeyPath:@"contentOffset"
              options:kNilOptions
              context:(__bridge void *)self];
}

#pragma mark - 滚动监听

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != (__bridge void *)self) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    CGFloat contentOffsetX = self.contentOffset.x;
    CGFloat scrollViewWidth = self.bounds.size.width;

    if (contentOffsetX <= 0 || contentOffsetX >= 2 * scrollViewWidth) {
        if (contentOffsetX <= 0) {
            _rightImageView.tag = _centerImageView.tag;
            _rightImageView.image = _centerImageView.image;

            _centerImageView.tag = _leftImageView.tag;
            _centerImageView.image = _leftImageView.image;

            if (--_leftImageView.tag < 0) {
                _leftImageView.tag = _images.count - 1;
            }
            _leftImageView.image = _images[_leftImageView.tag];
        } else {
            _leftImageView.tag = _centerImageView.tag;
            _leftImageView.image = _centerImageView.image;

            _centerImageView.tag = _rightImageView.tag;
            _centerImageView.image = _rightImageView.image;

            if (++_rightImageView.tag > _images.count - 1) {
                _rightImageView.tag = 0;
            }
            _rightImageView.image = _images[_rightImageView.tag];
        }
        self.contentOffset = (CGPoint){ .x = scrollViewWidth };
    }
}

#pragma mark -

- (void)setImages:(NSArray<UIImage *> *)images
{
    _images = images.copy;

    _leftImageView.tag = 0;
    _leftImageView.image = _images[0];

    _centerImageView.tag = 1;
    _centerImageView.image = _images[1];

    _rightImageView.tag = 2;
    _rightImageView.image = _images[2];
}

@end
