//
//  LXCarouselScrollView.h
//  Demo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface LXCarouselScrollView : UIScrollView <UIScrollViewDelegate>

/// 禁用点击交互，默认 NO。
@property (nonatomic) IBInspectable BOOL disableTapAction;
/// 总页数，默认 0。
@property (nonatomic) IBInspectable NSInteger numberOfPages;
/// 定时器时间间隔，默认 2s。
@property (nonatomic) IBInspectable NSTimeInterval timeInterval;

/// 更新配置 block 和页数前调用此方法，配置 block 不会再被调用；如果开启了定时器，则定时器会被废止。
- (void)invalidate;
/// 刷新数据，用于配置的 block 会立即调用。
- (void)reloadData;

/// 开启定时器来自动滚动。若 numberOfPages 小于 2 则此方法无效果。
- (void)startTimer;
/// 如果开启了定时器则废止定时器。
- (void)stopTimer;

/// 提供 block 响应页面改变。
- (void)notifyWhenPageDidChangeUsingBlock:(void (^)(NSInteger currentPage))configuration;
/// 提供 block 响应图片点击。
- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(UIImageView *imageView, NSInteger index))block;
/// 提供 block 设置图片。
- (void)configureImageViewUsingBlock:(void (^)(UIImageView *imageView, NSInteger index))configuration;

@end

NS_ASSUME_NONNULL_END
