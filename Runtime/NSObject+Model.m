//
//  NSObject+Model.m
//  Runtime
//
//  Created by txx on 17/1/13.
//  Copyright © 2017年 txx. All rights reserved.
//

#import "NSObject+Model.h"
#import <objc/runtime.h>

static const void *birthdayKey = &birthdayKey;
@implementation NSObject (Model)

//解决警告：Convenience initialzer  missing  a self call to another initializer
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"


/**
 用runtime提供的函数遍历Model自身所有属性，如果属性在json中有对应的值，则将其赋值。

 @param infoDic json数据
 @return model对象
 */
-(instancetype)initWithDictionary:(NSDictionary *)infoDic
{
    self = [self init];
    if (self) {
        //1.获取类的属性及属性对应的类型
        //属性列表
        NSMutableArray *keys = [NSMutableArray array];
        //属性类型
        NSMutableArray *types = [NSMutableArray array];
        
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList([self class], &count);
        for (int i = 0; i<count; i++) {
            objc_property_t property = properties[i];
            const char *cname = property_getName(property);
            NSString *ocname = [NSString stringWithUTF8String:cname];
            [keys addObject:ocname];
            
            NSString *type = [NSString stringWithUTF8String:property_getAttributes(property)];
            [types addObject:type];
        }
        free(properties);
        
        //2.根据类型给属性赋值
        for (NSString *key in keys) {
            //如果出现属性名和字典中key不对照时，可以在此处单独处理
            id value = [infoDic valueForKey:key];
            if (value == nil) continue ;
            [self setValue:value forKey:key];
        }
    }
    return self;
}
-(void)setBirthday:(NSString *)birthday
{
    objc_setAssociatedObject(self, birthdayKey, birthday, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSString *)birthday
{
    return objc_getAssociatedObject(self, birthdayKey);
}
@end
