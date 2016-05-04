//
//  ViewController.m
//  ScrollViewDemo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "ViewController.h"
#import "LXScrollView.h"

@interface ViewController ()
@property (nonatomic) IBOutlet LXScrollView *scrollView;
@property (nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic) NSArray *images;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pageControl.numberOfPages = 5;

    self.images = @[ [UIImage imageNamed:@"image_0"],
                     [UIImage imageNamed:@"image_1"],
                     [UIImage imageNamed:@"image_2"],
                     [UIImage imageNamed:@"image_3"],
                     [UIImage imageNamed:@"image_4"], ];

    __weak typeof(self) weakSelf = self;

    self.scrollView.numberOfPages = 5;
    [self.scrollView configureImageViewAtIndex:^(UIImageView * _Nonnull imageView, NSUInteger index) {
        imageView.image = weakSelf.images[index];
    }];

    [self.scrollView configurePageControlForCurrentPage:^(NSUInteger currentPage) {
        weakSelf.pageControl.currentPage = currentPage;
    }];

    [self.scrollView notifyWhenImageViewDidTapUsingBlock:^(UIImageView * _Nonnull imageView, NSUInteger index) {
        NSLog(@"%@, index:%@", imageView, @(index));
    }];
    
    self.scrollView.timeInterval = 2;
    [self.scrollView startTimer];
}

@end
