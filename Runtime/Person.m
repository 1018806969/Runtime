//
//  Person.m
//  Runtime
//
//  Created by txx on 17/1/13.
//  Copyright © 2017年 txx. All rights reserved.
//

#import "Person.h"
#import <objc/runtime.h>

@interface Person()<NSCoding>

@property(nonatomic,strong)NSString *salary;
@property(nonatomic,assign)CGFloat   length;

@end

@implementation Person

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.salary = @"200000";
    }
    return self;
}
-(void)eat
{
    NSLog(@"吃饭%@",NSStringFromClass([super class]));
    
}

-(void)sleep
{
    NSLog(@"睡觉");
}

-(void)work
{
    NSLog(@"工作");
}

-(void)searchFriend:(NSString *)friend
{
    NSLog(@"找朋友");
}

/**
 对象序列化协议方法

 @param aCoder NSCoder对象
 */
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    NSLog(@"--编码---encodeWithCoder:(NSCoder *)aCoder-----");
    unsigned int count ;
    
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        
        const char *cname = property_getName(property);
        NSString *ocName = [NSString stringWithUTF8String:cname];
        
        //通过关键词取值
        NSString *value = [self valueForKey:ocName];
        
        //编码属性
        [aCoder encodeObject:value forKey:ocName];
        NSLog(@"value=%@,key=%@",value,ocName);
    }
    free(properties);
}
/**
 对象序列化协议方法

 @param aDecoder 编码对象
 @return obj
 */
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"--解码----(instancetype)initWithCoder:(NSCoder *)aDecoder-----");
    unsigned int count ;
    
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    for (int i = 0; i<count; i++) {
        objc_property_t property = properties[i];
        
        const char *cname = property_getName(property);
        NSString *ocName = [NSString stringWithUTF8String:cname];
        
        //解码属性值
        NSString *value = [aDecoder decodeObjectForKey:ocName];
        
        [self setValue:value forKey:ocName];
        NSLog(@"value=%@,key=%@",value,ocName);

    }
    free(properties);
    return self ;

}


@end
