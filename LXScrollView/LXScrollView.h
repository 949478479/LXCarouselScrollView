//
//  LXScrollView.h
//  ScrollViewDemo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface LXScrollView : UIScrollView

/// 定时器时间间隔，默认 2s
@property (nonatomic) IBInspectable double timeInterval;
/// 禁用点击交互，默认不禁用
@property (nonatomic) IBInspectable BOOL disableTapAction;
/// 总页数，默认 0
@property (nonatomic) IBInspectable NSUInteger numberOfPages;
/// 内容显示模式，默认为 UIViewContentModeScaleToFill
@property (nonatomic) UIViewContentMode contentModeOfImageView;

/// 若可能处于滚动中，则更新数据前需调用此方法，定时器也会被废止
- (void)prepareForReloadData;

/// 初次加载，以及图片或页数发生变化时需调用此方法，相应的配置块会被立即调用
- (void)reloadData;

/// 开启定时器进行自动滚动，若 numberOfPages 小于 2 则忽略
- (void)startTimer;

/// 如果开启了定时器则废止定时器
- (void)invalidateTimer;

/// 根据块所提供的 currentPage 参数来配置页码控件的当前页码
- (void)configurePageControlForCurrentPage:(void (^)(NSUInteger currentPage))configuration;

/// 根据块所提供的 imageView 和 index 参数来设置图片
- (void)configureImageViewAtIndex:(void (^)(UIImageView *imageView, NSUInteger index))configuration;

/// 图片被点击时会调用此块
- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(UIImageView *imageView, NSUInteger index))block;

@end

NS_ASSUME_NONNULL_END
