//
//  TestCollectionViewController.m
//  HelloSensorsAnalytics
//
//  Created by ziven.mac on 2017/11/3.
//  Copyright © 2017年 SensorsData. All rights reserved.
//

#import "TestCollectionViewController.h"

@interface TestCollectionViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property(nonatomic,strong)NSMutableArray * dataArray;
@property(nonatomic,strong)UICollectionView *collectionView;
@end

@implementation TestCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArray = [NSMutableArray arrayWithArray:@[@1,@2,@3,@4]];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView = [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"identifier"];
    [self.view addSubview:self.collectionView];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArray.count;
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"identifier" forIndexPath:indexPath];
    
    for ( UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    [button setBackgroundColor:[UIColor whiteColor]];
//    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    [button setTitle:[NSString stringWithFormat:@"%@",self.dataArray[indexPath.item]] forState:UIControlStateNormal];
//    button.frame = CGRectMake(0, 0, 60, 60);
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    label.text = [NSString stringWithFormat:@"%ld:%@",(long)indexPath.section, self.dataArray[indexPath.item]];
    label.textColor = [UIColor redColor];
    [cell.contentView addSubview:label];
//    [cell.contentView addSubview:button];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(60, 60);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

@end
