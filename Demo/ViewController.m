//
//  ViewController.m
//  Demo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

#import "ViewController.h"
#import "LXCarouselScrollView.h"

@interface ViewController ()
@property (nonatomic) IBOutlet LXCarouselScrollView *scrollView;
@property (nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic) NSArray *images;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.images = @[ [UIImage imageNamed:@"image_0"],
                     [UIImage imageNamed:@"image_1"],
                     [UIImage imageNamed:@"image_2"],
                     [UIImage imageNamed:@"image_3"],
                     [UIImage imageNamed:@"image_4"], ];

    self.pageControl.numberOfPages = 5;

    self.scrollView.timeInterval = 2;
    self.scrollView.numberOfPages = 5;

    __weak typeof(self) weakSelf = self;

    [self.scrollView configureImageViewUsingBlock:^(UIImageView * _Nonnull imageView, NSInteger index) {
        imageView.image = weakSelf.images[index];
    }];

    [self.scrollView notifyWhenPageDidChangeUsingBlock:^(NSInteger currentPage) {
        weakSelf.pageControl.currentPage = currentPage;
    }];

    [self.scrollView notifyWhenImageViewDidTapUsingBlock:^(UIImageView * _Nonnull imageView, NSInteger index) {
        NSLog(@"%@, index:%@", imageView, @(index));
    }];

    [self.scrollView reloadData];
    [self.scrollView startTimer];
}

- (IBAction)changeNumberOfPages:(UISegmentedControl *)sender
{
    [self.scrollView invalidate];

    switch (sender.selectedSegmentIndex) {
        case 0:
            self.images = @[ [UIImage imageNamed:@"image_0"],
                             [UIImage imageNamed:@"image_1"],
                             [UIImage imageNamed:@"image_2"],
                             [UIImage imageNamed:@"image_3"],
                             [UIImage imageNamed:@"image_4"], ];
            break;
        case 1:
            self.images = @[ [UIImage imageNamed:@"image_0"],
                             [UIImage imageNamed:@"image_1"],
                             [UIImage imageNamed:@"image_3"], ];
            break;
        case 2:
            self.images = @[ [UIImage imageNamed:@"image_0"],
                             [UIImage imageNamed:@"image_1"], ];
            break;
        case 3:
            self.images = @[ [UIImage imageNamed:@"image_0"], ];
            break;
        case 4:
            self.images = nil;
            break;
        default:
            break;
    }

    self.scrollView.numberOfPages = self.images.count;
    self.pageControl.numberOfPages = self.images.count;

    [self.scrollView reloadData];
    [self.scrollView startTimer];
}

@end
