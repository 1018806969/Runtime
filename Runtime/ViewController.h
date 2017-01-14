//
//  ViewController.h
//  Runtime
//
//  Created by txx on 17/1/13.
//  Copyright © 2017年 txx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

/*  runtime:
是一套底层的C语言API，为iOS内部的核心之一，我们平时编写的iOS代码，底层都是基于runtime实现的。
*/

/*比如，oc的代码 [receiver message];
  底层运行时会被编译成runtime的代码 objc_msdSend(receiver, selector);
  如果有参数如：[receiver message:(id)arg...];
  底层运行时会被编译成runtime的代码 objc_msgSend(receiver, selector, arg1, arg2, ...)
 */

/*
  以上你可能看不出它的价值，但是我们需要了解的是 Objective-C 是一门动态语言，它会将一些工作放在代码运行时才处理而并非编译时。也就是说，有很多类和成员变量在我们编译的时是不知道的，而在运行时，我们所编写的代码会转换成完整的确定的代码运行。
 因此，只有编译器是不够的，我们还需要一个运行时系统(Runtime system)来处理编译后的代码。
 
 Runtime 基本是用 C 和汇编写的，由此可见苹果为了动态系统的高效而做出的努力。苹果和 GNU 各自维护一个开源的 Runtime 版本，这两个版本之间都在努力保持一致。
 */

/*
 oc在3种层面上和runtime system交互
 
 1.通过oc源代码
 编译器在编译时会将oc代码转化为运行时代码
 
 2.通过Foundation框架的NSObject类定义的方法
 cocoa touch程序中NSObject是所有类的父类，所以都继承了其行为，一些情况下，NSObject类仅仅定义了完成某件事情的模板，并没有提供所需的代码，例如-description方法，该方法返回类内容的字符串表示，主要用来调试程序，NSObject并不知道子类的内容，所以它只返回类的名字和对象的地址，子类都可以重新实现。
 还有一些 NSObject 的方法可以从 Runtime 系统中获取信息，允许对象进行自我检查。例如：
 -class方法返回对象的类；
 -isKindOfClass: 和 -isMemberOfClass: 方法检查对象是否存在于指定的类的继承体系中(是否是其子类或者父类或者当前类的成员变量)；
 -respondsToSelector: 检查对象能否响应指定的消息；
 -conformsToProtocol:检查对象是否实现了指定协议类的方法；
 -methodForSelector: 返回指定方法实现的地址。
 
 3.通过runtime库函数直接调用
 runtime system是具有公共接口的动态共享库，这意味着我们在使用中只需引入objc/Runtime.h头文件即可。
 */

/*
 runtime的一些术语，以及这些术语对应的数据结构
 
 1.SEL
     是selector在objc中的表示（Swift 中是 Selector 类），即方法选择器，作用和名字一样，Objc 在相同的类中不会有命名相同的两个方法。selector 对方法名进行包装，以便找到对应的方法实现。
     他的数据格式是 typedef struct objc_selector *SEL;
     我们可以看出它是个映射到方法的 C 字符串，你可以通过 Objc 编译器命令@selector() 或者 Runtime 系统的 sel_registerName 函数来获取一个 SEL 类型的方法选择器。
 注意：
 不同类中相同名字的方法所对应的selector 是相同的，由于变量的类型不同，所以不会导致它们调用方法实现混乱。
 
 2.id
   id是一个参数类型，是指向某个类的实例的指针，定义如下
 typedef struct objc_object *id;
 struct objc_object { Class isa; };
 以上定义，看到 objc_object 结构体包含一个 isa 指针，根据 isa 指针就可以找到对象所属的类。
 注意：
 isa 指针在代码运行时并不总指向实例对象所属的类型，所以不能依靠它来确定类型，要想确定类型还是需要用对象的 -class 方法。
 
 3.Class ：typedef struct objc_class *Class;
   其实是指向objc_class结构体的指针，objc_class的数据结构如下：
 struct objc_class {
 Class isa  OBJC_ISA_AVAILABILITY;
 
 #if !__OBJC2__
 Class super_class                                        OBJC2_UNAVAILABLE;
 const char *name                                         OBJC2_UNAVAILABLE;
 long version                                             OBJC2_UNAVAILABLE;
 long info                                                OBJC2_UNAVAILABLE;
 long instance_size                                       OBJC2_UNAVAILABLE;
 struct objc_ivar_list *ivars                             OBJC2_UNAVAILABLE;
 struct objc_method_list **methodLists                    OBJC2_UNAVAILABLE;
 struct objc_cache *cache                                 OBJC2_UNAVAILABLE;
 struct objc_protocol_list *protocols                     OBJC2_UNAVAILABLE;
 #endif
 } OBJC2_UNAVAILABLE;
 从objc_class可以看出，一个运行时类中关联了他的父类指针、类名、成员变量、方法、缓存及附属的协议。

 4.Method
 Method代表类中某个方法的类型
 typedef struct objc_method *Method;
 struct objc_method {
 SEL method_name     方法名                                     OBJC2_UNAVAILABLE;
 char *method_types  方法类型：参数类型和返回值类型                  OBJC2_UNAVAILABLE;
 IMP method_imp      指向了方法的实现，本质是一个函数指针             OBJC2_UNAVAILABLE;
 }
 
 5.Ivar
 Ivar是表示成员变量的类型
 typedef struct objc_ivar *Ivar;
 struct objc_ivar {
 char *ivar_name                                          OBJC2_UNAVAILABLE;
 char *ivar_type                                          OBJC2_UNAVAILABLE;
 int ivar_offset                                          OBJC2_UNAVAILABLE;  基地址偏移字节
 #ifdef __LP64__
 int space                                                OBJC2_UNAVAILABLE;
 #endif
 }
 
 6.IMP
 IMP在objc.h中的定义是： typedef id (*IMP)(id, SEL, ...);
 它就是一个函数指针，是有编译器生成，当你发起一个 ObjC 消息之后，最终它会执行的那段代码，就是由这个函数指针指定的。而 IMP 这个函数指针就指向了这个方法的实现。
 
 如果得到了执行某个实例某个方法的入口，我们就可以绕开消息传递阶段，直接执行方法，这在后面 Cache 中会提到。
 你会发现 IMP 指向的方法与 objc_msgSend 函数类型相同，参数都包含 id 和 SEL 类型。每个方法名都对应一个 SEL 类型的方法选择器，而每个实例对象中的 SEL 对应的方法实现肯定是唯一的，通过一组 id和 SEL 参数就能确定唯一的方法实现地址。
 而一个确定的方法也只有唯一的一组 id 和 SEL 参数。
 
 7.Cache
 cache定义如下：typedef struct objc_cache *Cache
 struct objc_cache {
 unsigned int mask     total = mask + 1                  OBJC2_UNAVAILABLE;
 unsigned int occupied                                    OBJC2_UNAVAILABLE;
 Method buckets[1]                                        OBJC2_UNAVAILABLE;
};
 Cache为方法调用的性能进行优化，每当实例对象接受一个消息时，它不会直接在isa指针指向的类的方法列表中遍历查找能够响应的方法，因为每次都要遍历效率太低了，而是优先在Cache中查找。
 
 8.Property
 typedef struct objc_property *Property;
 typedef struct objc_property *objc_property_t;//这个更常用
 可以通过class_copyPropertyList 和 protocol_copyPropertyList 方法获取类和协议中的属性：
 objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount)
 objc_property_t *protocol_copyPropertyList(Protocol *proto, unsigned int *outCount)
 注意：
 返回的是属性列表，列表中每个元素都是一个 objc_property_t 指针
 */

/*
 消息
 体会苹果官方文档中的messages aren’t bound to method implementations until Runtime。（消息直到运行时才会与方法实现进行绑定）
 消息发送步骤：
 1.首先检测这个 selector 是不是要忽略。比如 Mac OS X 开发，有了垃圾回收就不理会 retain，release 这些函数。
 2.检测这个 selector 的 target 是不是 nil，Objc 允许我们对一个 nil 对象执行任何方法不会 Crash，因为运行时会被忽略掉。
 3.如果上面两步都通过了，那么就开始查找这个类的实现 IMP，先从 cache 里查找，如果找到了就运行对应的函数去执行相应的代码。
 4.如果 cache 找不到就找类的方法列表中是否有对应的方法。
 5.如果类的方法列表中找不到就到父类的方法列表中查找，一直找到 NSObject 类为止。
 6.如果还找不到，就要开始进入动态方法解析了，后面会提到。
 在消息的传递中，编译器会根据情况在 objc_msgSend ， objc_msgSend_stret ， objc_msgSendSuper ， objc_msgSendSuper_stret 这四个方法中选择一个调用。如果消息是传递给父类，那么会调用名字带有 Super 的函数，如果消息返回值是数据结构而不是简单值时，会调用名字带有 stret 的函数。
 */


/*
 方法中隐藏的参数
 Q:我们经常用到关键字self，但是self是如何获取当前方法的对象呢？
 A:这也是runtime system的作用，self是在方法运行时被动态传入的。
 当 objc_msgSend 找到方法对应实现时，它将直接调用该方法实现，并将消息中所有参数都传递给方法实现，同时，它还将传递两个隐藏参数：
 接受消息的对象(self 所指向的内容，当前方法的对象指针)
 方法选择器(_cmd 指向的内容，当前方法的 SEL 指针)
 因为在源代码方法的定义中，我们并没有发现这两个参数的声明。它们时在代码被编译时被插入方法实现中的。尽管这些参数没有被明确声明，在源代码中我们仍然可以引用它们。
 这两个参数中， self更实用。它是在方法实现中访问消息接收者对象的实例变量的途径。
 
 这时我们可能会想到另一个关键字 super ，实际上 super 关键字接收到消息时，编译器会创建一个 objc_super 结构体：
 struct objc_super { id receiver; Class class; };
这个结构体指明了消息应该被传递给特定的父类。 receiver 仍然是 self 本身，当我们想通过 [super class] 获取父类时，编译器其实是将指向 self 的 id 指针和 class 的 SEL 传递给了 objc_msgSendSuper 函数。只有在 NSObject 类中才能找到 class 方法，然后 class 方法底层被转换为 object_getClass()， 接着底层编译器将代码转换为 objc_msgSend(objc_super->receiver, @selector(class))，传入的第一个参数是指向 self 的 id 指针，与调用 [self class] 相同，所以我们得到的永远都是 self 的类型。因此你会发现：
 // 这句话并不能获取父类的类型，只能获取当前类的类型名
 NSLog(@"%@", NSStringFromClass([super class]));在Person的eat方法中进行了实验

 
 */









//runtime中的Method类型：typedef struct objc_method *Method;

//Method类型是一个objc_method结构体指针，而结构体objc_method有三个成员变量

//struct objc_method {
//    SEL method_name                 OBJC2_UNAVAILABLE;   方法名
//    char *method_types              OBJC2_UNAVAILABLE;   参数和返回类型的描述字符串
//    IMP method_imp                  OBJC2_UNAVAILABLE;   方法具体实现的指针
//}                                   OBJC2_UNAVAILABLE;

//Method提供的方法

/*
// 函数调用，但是不接收返回值类型为结构体
method_invoke
// 函数调用，但是接收返回值类型为结构体
method_invoke_stret
// 获取函数名
method_getName
// 获取函数实现IMP
method_getImplementation
// 获取函数type encoding
method_getTypeEncoding
// 复制返回值类型
method_copyReturnType
// 复制参数类型
method_copyArgumentType
// 获取返回值类型
method_getReturnType
// 获取参数个数
method_getNumberOfArguments
// 获取函数参数类型
method_getArgumentType
// 获取函数描述
method_getDescription
// 设置函数实现IMP
method_setImplementation
// 交换函数的实现IMP
method_exchangeImplementations
*/



//参数类型编码和类型对照表
//编码值	含意
//c	代表char类型
//i	代表int类型
//s	代表short类型
//l	代表long类型，在64位处理器上也是按照32位处理
//q	代表long long类型
//C	代表unsigned char类型
//I	代表unsigned int类型
//S	代表unsigned short类型
//L	代表unsigned long类型
//Q	代表unsigned long long类型
//f	代表float类型
//d	代表double类型
//B	代表C++中的bool或者C99中的_Bool
//v	代表void类型
//*	代表char *类型
//@	代表对象类型
//#	代表类对象 (Class)
//:	代表方法selector (SEL)
//[array type]	代表array
//{name=type...}	代表结构体
//(name=type...)	代表union
//bnum	A bit field of num bits
//^type	A pointer to type
//?	An unknown type (among other things, this code is used for function pointers)




@end

