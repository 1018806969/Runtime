//
//  Person.h
//  Runtime
//
//  Created by txx on 17/1/13.
//  Copyright © 2017年 txx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol PersonDelegate <NSObject>



@end

typedef NS_ENUM(NSInteger,TSex)
{
    TSexMan,
    TSexWoman
};

@interface Person : NSObject

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *adress;

@property (nonatomic,strong) NSString *phone;
@property (nonatomic,assign) TSex      sex;

@property (nonatomic,assign) CGFloat   hieght;



-(void)eat;

-(void)sleep;

-(void)work;


@end
