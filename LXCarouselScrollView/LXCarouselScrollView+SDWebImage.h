//
//  LXCarouselScrollView+SDWebImage.h
//
//  Created by 从今以后 on 2017/9/17.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "LXCarouselScrollView.h"

/// 该分类使用 SDWebImage 加载网络图片，因此需要引入 SDWebImage
/// 直接设置图片地址即可，内部会自行调用 -[LXCarouselScrollView configureImageViewUsingBlock:] 方法
@interface LXCarouselScrollView (SDWebImage)

/// 网络图片地址数组
- (void)lx_setImageURLs:(NSArray<NSURL *> *)imageURLs;

/// 在下载图片过程中显示的占位图片，设置该属性将不再显示活动指示器
- (void)lx_setPlaceholderImage:(UIImage *)image;

/// 在下载图片过程中是否显示活动指示器，默认不显示
- (void)lx_setShowActivityIndicatorView:(BOOL)show;

- (void)lx_setIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@end
