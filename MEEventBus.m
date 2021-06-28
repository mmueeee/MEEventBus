//
//  MEEventBus.m
//  BindingX
//
//  Created by ylin on 2021/6/27.
//

#import "MEEventBus.h"
#import <objc/runtime.h>

@interface _MEEventSubscriberHandleImpl : NSObject<MEEventSubscriberHandle>

@property (nonatomic, weak) id weakValue;
@property (nonatomic, strong) id strongValue;
- (instancetype)initWithValue:(id)value;
- (id)value;

@end

@implementation MEEventBus
{
    NSMutableDictionary *subscriberMapping;
    NSRecursiveLock *lock;
}

+ (instancetype)shared
{
    static id sharedManager = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    subscriberMapping = [[NSMutableDictionary alloc] init];
    lock = [[NSRecursiveLock alloc] init];
    return self;
}

- (id<MEEventSubscriberHandle>)subscriberWithProtocol:(Protocol *)protocol
                                             observer:(id)observer
{
    if (!protocol || !observer) {
        return nil;
    }
    
    [lock lock];
    NSString *name = NSStringFromProtocol(protocol);
    NSMutableArray *obsHandle = [self _getObserversWithName:name];
    
    /// 检查已有的
    _MEEventSubscriberHandleImpl *handle;
    for (_MEEventSubscriberHandleImpl *object in obsHandle) {
        if (object.value == observer) {
            handle = object;
        }
    }
    
    if (!handle) {
        handle = [[_MEEventSubscriberHandleImpl alloc] initWithValue:observer];
        [obsHandle addObject:handle];
    }
    [lock unlock];
    return handle;
}

- (void)unsubscriberWithProtocol:(Protocol *)protocol
                        observer:(id)observer
{
    if (!protocol || !observer) {
        return;
    }
    
    [lock lock];
    NSString *name = NSStringFromProtocol(protocol);
    NSMutableArray *obsHandle = [self _getObserversWithName:name];
    
    /// 检查
    _MEEventSubscriberHandleImpl *handle;
    for (_MEEventSubscriberHandleImpl *object in obsHandle) {
        /// 此处兼容传入的 observer 可以是一个_MEEventSubscriberHandleImpl实例
        if (object.value == observer || observer == object) {
            handle = object;
            break;
        }
    }
    if (handle) {
        [obsHandle removeObject:handle];
    }
    [lock unlock];
}

- (void)unsubscriberWithObserver:(id)observer
{
    if (!observer) {
        return;
    }
    [lock lock];
    
    for (NSMutableArray *obsHandle in subscriberMapping.allValues) {
        _MEEventSubscriberHandleImpl *handle;
        for (_MEEventSubscriberHandleImpl *object in obsHandle) {
            /// 此处兼容传入的 observer 可以是一个_MEEventSubscriberHandleImpl实例
            if (object.value == observer || observer == object) {
                handle = object;
                break;
            }
        }
        if (handle) {
            [obsHandle removeObject:handle];
        }
    }
    
    [lock unlock];
}

#pragma mark - private

- (NSArray <_MEEventSubscriberHandleImpl *>*)getObserversWithProtocol:(Protocol *)protocol
{
    [lock lock];
    NSString *name = NSStringFromProtocol(protocol);
    NSMutableArray *obsHandle = [self _getObserversWithName:name];
    
    NSMutableArray *newHandles = [[NSMutableArray alloc] init];
    NSInteger index = 0;
    while (index < obsHandle.count) {
        _MEEventSubscriberHandleImpl *handle = obsHandle[index];
        if (handle.value) {
            [newHandles addObject:handle];
        } else {
            [obsHandle removeObject:handle];
        }
        index ++;
    }
    [lock unlock];
    return newHandles.copy;
}

- (NSMutableArray <_MEEventSubscriberHandleImpl *>*)_getObserversWithName:(NSString *)name
{
    NSMutableArray *list;
    list = subscriberMapping[name];
    if (!list) {
        list = [[NSMutableArray alloc] init];
        subscriberMapping[name] = list;
    }
    return list;
}

@end

@implementation _MEEventSubscriberHandleImpl

@synthesize isMain;

@synthesize isStrong;

@synthesize isSync;

- (instancetype)initWithValue:(id)value
{
    self = [super init];
    if (self) {
        self.weakValue = value;
        self.isStrong = false;
    }
    return self;
}

- (void)setIsStrong:(BOOL)isStrong_
{
    if (isStrong == isStrong_) {
        return;
    }
    isStrong = isStrong_;
    if (isStrong) {
        self.strongValue = self.weakValue;
        self.weakValue = nil;
    } else {
        self.weakValue = self.strongValue;
        self.strongValue = nil;
    }
}

- (id)value
{
    return isStrong ? self.strongValue : self.weakValue;
}

@end


@interface MEEventBusDispatcherForwarder: NSProxy {
@public
    Protocol *__protocol__;
}
@end

@implementation MEEventBusDispatcherForwarder

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    struct objc_method_description method;
    method = protocol_getMethodDescription(self->__protocol__, aSelector, NO, YES);
    if (method.types == nil) {
        method = protocol_getMethodDescription(self->__protocol__, aSelector, YES, YES);
    }
    return [NSMethodSignature signatureWithObjCTypes:method.types];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSArray <_MEEventSubscriberHandleImpl *> *list;
    list = [MEEventBus.shared getObserversWithProtocol:self->__protocol__];
    for (NSInteger i = 0; i < list.count; i ++) {
        _MEEventSubscriberHandleImpl *handle = list[i];
        
        void(^call)(void) = ^{
            if ([handle.value respondsToSelector:invocation.selector]) {
                [invocation invokeWithTarget:handle.value];
            }
        };
        
        if (handle.isMain && !NSThread.isMainThread) {
            if (handle.isSync) {
                dispatch_sync(dispatch_get_main_queue(), call);
            } else {
                dispatch_async(dispatch_get_main_queue(), call);
            }
        } else {
            call();
        }
    }
}

@end

id __protocol_dispatcher_forwarder(Protocol *p) {
    MEEventBusDispatcherForwarder *fowarder = [MEEventBusDispatcherForwarder alloc];
    fowarder->__protocol__ = p;
    return fowarder;
}
