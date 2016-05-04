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

@property (nonatomic) NSUInteger numberOfPages;

@property (nonatomic) NSTimeInterval timeInterval;

- (void)startTimer;

- (void)invalidateTimer;

- (void)configurePageControlForCurrentPage:(void (^)(NSUInteger currentPage))configuration;

- (void)configureImageViewAtIndex:(void (^)(UIImageView *imageView, NSUInteger index))configuration;

- (void)notifyWhenImageViewDidTapUsingBlock:(void (^)(UIImageView *imageView, NSUInteger index))block;

@end

NS_ASSUME_NONNULL_END
