//
//  NSObject+Model.h
//  Runtime
//
//  Created by txx on 17/1/13.
//  Copyright © 2017年 txx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Model)

/**
 runtime的应用：给catalog添加属性birthday
 */
@property(nonatomic,strong)NSString *birthday;

-(instancetype)initWithDictionary:(NSDictionary *)infoDic;



@end
