# MEEventBus
EventBus 基于协议的事件总线

## 使用

> 定义事件
```objc
@protocol XXBizAction <NSObject>

- (void)didUpdate:(id)sender data:(XXDataModel *)data;

@end
```

> 订阅/取消
```objc
@interface MoudleA ()<XXBizAction>
@end

@implementation MoudleA

// 订阅
- (void)subscriber
{
    id<MEEventSubscriberHandle> handle;
    handle = MEEventSubscriber(XXBizAction, self);
    // handle.isMian = true;
    // ...
}

// 取消订阅
- (void)unsubscriber
{
    handle = MEEventUnSubscriber(XXBizAction, self);
}

// 实现事件方法
- (void)didUpdate:(id)sender data:(XXDataModel *)data
{
    //TODO: ...
}

@end
```

> 发布事件
```objc
// 发布事件
@implementation MoudleB

- (void)publisher
{
    XXDataModel *data = nil;
    [MEEventPublisher(MEEventSubscriberHandle) didUpdate:self data:data];
}

```

## 功能计划

- [x] 基础订阅/取消/发布
- [ ] 规划中...