//
//  ViewController.m
//  Runtime
//
//  Created by txx on 17/1/13.
//  Copyright © 2017年 txx. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import <objc/runtime.h>
#import "NSObject+Model.h"

@interface ViewController ()<PersonDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[Person new]eat];
    
    //runtime:运行时，是一套比较底层的纯c语言API，属于一个C语言库。在oc的运行中，都会转化为runtime的C语言代码，是oc的幕后工作者
    
    
    //runtime的简单使用：
    
    
    //1.获取一个类的全部成员变量（公有的和私有的）
    [self allInstanceVarInClass:[Person class]];
    
    //2.获取一个类的全部属性名（公有的和私有的）
    [self allPropertyNameInClass:[Person class]];
    
    //3.获取一个类的全部方法（公有的和私有的）
    [self allMethodInClass:[Person class]];
    
    //4.获取一个类遵循的全部协议（公有的和私有的）
    [self allProtocalInClass:[self class]];
    
    //5.归档和解档,在Person中实现了NSCoding协议
    [self encode_decode];
    
    //6.交换方法的实现 method swizzling
    [self exchangeIMP];
    
    //7.json转model
    [self translateJsonToModel];
    
    //8.操作私有变量
    [self accessPrivateVariable];
    
    //9.关联对象
    [self associateObj];
    
    
    
}
-(void)associateObj
{
    NSLog(@"---------------------关联对象---------------------------");
    /*
     1.关联对象是指某个oc对象通过一个唯一的key链接到一个类的实例上，举个例子：
    xiaoming是Person类的一个实例，他的dog（一个OC对象）通过一根绳子（key）被他牵着散步，这可以说xiaoming和dog是关联起来的，当然xiaoming可以牵着多个dog。
     */
    
    /*
     runtime 提供的方法：
     //关联对象,arg依次代表：被关联的对象如：小明，关联的key要求唯一，关联的对象如dog，内存管理策略：
     OBJC_ASSOCIATION_ASSIGN = 0,
     OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
     OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
     OBJC_ASSOCIATION_RETAIN = 01401,
     OBJC_ASSOCIATION_COPY = 01403
     当对象被释放时，会根据这个策略来决定是否释放关联的对象，当策略是RETAIN/COPY时，会释放（release）关联的对象，当是ASSIGN，将不会释放。
     值得注意的是，我们不需要主动调用removeAssociated来接触关联的对象，如果需要解除指定的对象，可以使用setAssociatedObject置nil来实现。
     void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
     //获取关联的对象
     id objc_getAssociatedObject(id object, const void *key)
     //移除关联的对象
     void objc_removeAssociatedObjects(id object)
     */
    
    /*
     关联对象的应用
     1.给catalog添加属性
     这是最常用的一个模式，通常我们会在类声明里面添加属性，但是出于某些需求（如前言描述的情况），我们需要在分类里添加一个或多个属性的话，编译器就会报错，这个问题的解决方案就是使用runtime的关联对象。
     */
    
    //给NSObject的catalog Model添加属性birthday
    Person *person = [Person new];
    person.birthday = @"2017-1-14";
    NSLog(@"给分类添加的属性的值为%@",person.birthday);
    
}
-(void)accessPrivateVariable
{
    NSLog(@"--------------访问私有变量---------------");
    //oc中没有真正意义上的私有变量，要让成员变量私有，要把其放在.m中声明，不对外暴露。如果我们知道这个成员变量的名称，就可以通过runtime获取成员变量，再通过getIvar来获取他的值；
    
    Person *person = [[Person alloc]init];
    Ivar ivar = class_getInstanceVariable([Person class], "_salary");
    //获取私有变量的值
    NSString *salary = object_getIvar(person, ivar);
    NSLog(@"--私有变量旧值为%@",salary);
    
    //重置私有变量的值
    object_setIvar(person, ivar, @"400000");
    NSString *newSalary = object_getIvar(person, ivar);
    NSLog(@"--私有变量新值为%@",newSalary);

}
-(void)translateJsonToModel
{
    NSLog(@"--------------json转model---------------");
    NSDictionary *jsonDictionary = @{@"name"   :@"唐旋",
                                     @"adress":@"上海虹口",
                                     @"phone"  :@"180****3657",
                                     @"hieght" :@180.0,
                                     @"cao"    :@545
                                     };
    //给NSObject添加catalog，利用runtime操作
    Person *person = [[Person alloc]initWithDictionary:jsonDictionary];
    
    NSLog(@"%@",person);
    
    
}
-(void)exchangeIMP
{
    NSLog(@"--------------交换方法的实现---------------");
    Method method1 = class_getInstanceMethod([Person class], @selector(eat));
    Method method2 = class_getInstanceMethod([self class], @selector(reWriteEat));
    
    method_exchangeImplementations(method1, method2);
    
    Person *person = [[Person alloc]init];
    [person eat];
}
-(void)reWriteEat
{
    NSLog(@"重新吃了一遍");
}
-(void)encode_decode
{
    Person *person = [[Person alloc]init];
    person.name = @"唐旋";
    person.sex = TSexMan;
    person.hieght = 180.0f;
    
    //序列化
    NSString *path = [NSString stringWithFormat:@"%@/Documents/tang",NSHomeDirectory()];
    [NSKeyedArchiver archiveRootObject:person toFile:path];
    
    //反序列化
    Person *p = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSLog(@"%@",p);
    
    
}
-(void)allProtocalInClass:(Class)class
{
    NSLog(@"----------获取一个类遵循的全部协议------------");

    unsigned int count ;
    
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(class, &count);
    
    for (int i = 0; i < count; i++) {
        Protocol *protocol = protocols[i];
        const char *name = protocol_getName(protocol);
        NSString *protocolName = [NSString stringWithUTF8String:name];
        NSLog(@"第%d个协议是%@",i,protocolName);
    }
    free(protocols);
}
-(void)allMethodInClass:(Class)class
{
    NSLog(@"----------获取一个类的全部方法------------");

    unsigned int count ;
    
    //获取指向该类所有方法的指针
    Method *methods = class_copyMethodList(class, &count);
    
    for (int i = 0; i < count; i++) {
        Method method = methods[i];
        
        SEL sel = method_getName(method);
        
        //获取方法名字方法1
        const char *name = sel_getName(sel);
        NSString *methodName = [NSString stringWithUTF8String:name];
        //方法2
        //NSString *methodName = NSStringFromSelector(sel);

        //获取方法中的参数个数
        int arguments = method_getNumberOfArguments(method);
        
        /*
         通过下面的打印发现参数个数总是比你看到的参数个数多两个，即参数个数最少是两个，例如方法eat你看到根本没有参数，开始打印参数个数确实两个，原因是：
         
         eat方法在编译时会被转化为：((void (*)(id, SEL))objc_msgSend)((id)m, @selector(getMethods));
         此时看就是2个参数了。
         */
        NSLog(@"第%d个方法是%@，参数个数是%d",i,methodName,arguments);
        
        
        // 获取方法的参数类型
        unsigned int argumentsCount = method_getNumberOfArguments(method);
        char argName[512] = {};
        for (unsigned int j = 0; j < argumentsCount; ++j) {
            method_getArgumentType(method, j, argName, 512);
            /*
             打印参数类型时会发现参数类型为一些难以理解的编码，如：@ ： q v 等
             参数类型编码和类型对照表在ViewController.h中。
             */
            NSLog(@"第%u个参数类型为：%s", j, argName);
            memset(argName, '\0', strlen(argName));
        }
        
        char returnType[512] = {};
        method_getReturnType(method, returnType, 512);
        NSLog(@"返回值类型：%s", returnType);
    }
    free(methods);
}
-(void)allPropertyNameInClass:(Class)class
{
    NSLog(@"----------获取一个类的全部属性名------------");

    unsigned int count ;
    
    //获取指向该类所有属性的指针
    objc_property_t *properties = class_copyPropertyList(class, &count);
    
    for (int i = 0; i < count; i++) {
        //获取该类的一个属性的指针
        objc_property_t property = properties[i];
        //获取属性的名字
        const char *name = property_getName(property);
        //将c的字符串转为oc的
        NSString *key = [NSString stringWithUTF8String:name];
        NSLog(@"第%d个属性是%@",i,key);
    }
    //释放
    free(properties);
}
-(void)allInstanceVarInClass:(Class)class
{
    NSLog(@"----------获取一个类的全部成员变量------------");
    
    unsigned int count ;
    
    //获取成员变量的结构体
    Ivar *ivars = class_copyIvarList(class, &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        //根据ivar获得其成员变量的名称
        const char *name = ivar_getName(ivar);
        //将c的字符串转化为oc的
        NSString *key = [NSString stringWithUTF8String:name];
        NSLog(@"第%d个成员变量是%@",i,key);
    }
    //释放
    free(ivars);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
