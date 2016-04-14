//
//  ViewController.m
//  ScrollViewDemo
//
//  Created by 从今以后 on 16/4/13.
//  Copyright © 2016年 千行时线. All rights reserved.
//

#import "ViewController.h"
#import "LXScrollView.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (nonatomic) IBOutlet LXScrollView *scrollView;
@property (nonatomic) IBOutlet UIPageControl *pageControl;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//
//    UIGraphicsBeginImageContextWithOptions(self.label.bounds.size, YES, 0);
//    for (int i = 0; i < 5; ++i) {
//        CGContextClearRect(UIGraphicsGetCurrentContext(), self.label.bounds);
//        self.label.text = [NSString stringWithFormat:@"%d", i];
//        [self.label.layer drawInContext:UIGraphicsGetCurrentContext()];
//        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//        NSString *path = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"image_%d.png", i]];
//        [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
//    }
//    UIGraphicsEndImageContext();
//    return;
    self.scrollView.images = @[ [UIImage imageNamed:@"image_0"],
                                [UIImage imageNamed:@"image_1"],
                                [UIImage imageNamed:@"image_2"],
                                [UIImage imageNamed:@"image_3"],
                                [UIImage imageNamed:@"image_4"], ];
}

@end
