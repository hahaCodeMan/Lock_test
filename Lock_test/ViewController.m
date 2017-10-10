//
//  ViewController.m
//  Lock_test
//
//  Created by Risen on 2017/10/10.
//  Copyright © 2017年 Risen. All rights reserved.
//

#import "ViewController.h"
#import <libkern/OSAtomic.h>
#import <pthread.h>

@interface ViewController ()

@end

@implementation ViewController
   //OSSpinLock 自旋锁
- (void)viewDidLoad {
    [super viewDidLoad];
  // NSLock普通锁
   // [self nslock];
   // NSConditionLock 条件锁
    //[self nsconditionlock];
    //NSRecursiveLock递归锁
   // [self nsrecursivelock];
    //NSCondition线程锁
    //[self nscondition];
   // @synchronized 条件锁
    //[self synchronized];
    
    
    //dispatch_semaphore 信号量
     //[self dispatch_semaphore];
   // OSSpinLock 自旋锁
   // [self asspinlock];
    // pthread_mutex  互斥锁
    //[self pthread_mutex];
    //pthread_mutex_recursive 递归锁
    [self pthread_mutex_recursive];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)pthread_mutex_recursive{
    static pthread_mutex_t pLock;
    pthread_mutexattr_t attr ;
    pthread_mutexattr_init(&attr); //初始化attr并且给它赋予默认
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE); //设置锁类型, 这边是设置为递归锁
    pthread_mutex_init(&pLock, &attr);
    pthread_mutexattr_destroy(&attr); //销毁一个属性对象,在重新进行初始化之前该结构不能重新使用
    //1.线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock =^(int value){
            pthread_mutex_lock(&pLock);
            if (value > 0) {
                NSLog(@"value: %d",value);
                RecursiveBlock(value -1);
            }
            pthread_mutex_unlock(&pLock);
        };
        RecursiveBlock(5);
    });
    
}
-(void)pthread_mutex{
    static pthread_mutex_t pLock;
    pthread_mutex_init(&pLock, NULL);
    //1.线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        pthread_mutex_lock(&pLock);
        sleep(3);
        NSLog(@"线程1");
        pthread_mutex_unlock(&pLock);
    });
    //1.线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        NSLog(@"线程2 准备上锁");
        NSLog(@"we=%d",pthread_mutex_trylock(&pLock));
        pthread_mutex_lock(&pLock);
        NSLog(@"线程2");
        pthread_mutex_unlock(&pLock);
    });
}


-(void)dispatch_semaphore{
   //dispatch_semaphore_create(long value)
    //dispatch_semaphore_wait(dispatch_semaphore_t  _Nonnull dsema, dispatch_time_t timeout)
    //dispatch_semaphore_signal(dispatch_semaphore_t  _Nonnull dsema)
    dispatch_semaphore_t signal = dispatch_semaphore_create(0); //传入值必须 >=0,若传入为0则阻塞线程并等待timeout,时间到后会执行气候的语句
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 3.0f*NSEC_PER_SEC);
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 等待ing");
        dispatch_semaphore_wait(signal, overTime); //singal 值 -1
        NSLog(@"线程1");
        dispatch_semaphore_signal(signal); //singal 值 +1
        NSLog(@"线程1 发送信号");
        NSLog(@"-----------------------------------");
        
    });
   //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 等待ing");
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程2");
        dispatch_semaphore_signal(signal);
        NSLog(@"线程2 发送信号");
    });


}
-(void)synchronized{
 //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (self) {
            sleep(2);
            NSLog(@"线程1");
        }
    });
 //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized (self) {
            NSLog(@"线程2");
        }
    });

}
-(void)nscondition{
    NSCondition *cLock =[NSCondition new]; //线程锁
    
    
    
    //等待2秒
    
        //线程3
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"start");
        [cLock lock];
        [cLock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        NSLog(@"线程3");
        [cLock unlock];
    });
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [cLock lock];
        NSLog(@"线程1加锁成功");
        [cLock wait];
        NSLog(@"线程1");
        [cLock unlock];
    });
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [cLock lock];
        NSLog(@"线程2加锁成功");
        [cLock wait];
        NSLog(@"线程2");
        [cLock unlock];
    });
    
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       sleep(2);
       NSLog(@"唤醒一个等待的线程");
       [cLock signal];
    });
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//      sleep(2);
//      NSLog(@"唤醒所有等待的线程");
//      [cLock broadcast];
//  });
    
    /*
     wait：进入等待状态
waitUntilDate:：让一个线程等待一定的时间
    signal：唤醒一个等待的线程
    broadcast：唤醒所有等待的线程
     */
}
-(void)nslock{
    NSLock *lock =[NSLock new];
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 尝试加速ing...");
        [lock lock];
        sleep(3);//睡眠5秒
        NSLog(@"线程1");
        [lock unlock];
        NSLog(@"线程1解锁成功");
        
    });
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 尝试加速ing...");
        BOOL x = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:4]];
        if (x) {
            NSLog(@"线程2");
            [lock unlock];
        }else{
        
            NSLog(@"失败");
        }
    });

}
-(void)nsconditionlock{
    
    //相比于 NSLock 多了个 condition 参数，我们可以理解为一个条件标示。
   
    /*
     初始化NSConditionLock对象时,给了它的表示为 0
     */
    
    //执行tryLockWhenCondition:时我们传入的条件表示也是为0,可以检查线程1加锁成功
    //执行unlockWithCondition:时 这时候会把condition由 0修改为 1;
    
    //因为condition 修改为了 1, 会先走到 线程3, 然后 线程3又将condition修改为3
    //最后 走了线程2 的流程
    
    //根据运行的结果,  NSConditionLock还可以实现任务之间的依赖
    
    NSConditionLock *cLock =[[NSConditionLock alloc] initWithCondition:0];
    
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([cLock tryLockWhenCondition:0]) {
            NSLog(@"线程1");
            [cLock unlockWithCondition:1];
        }else{
            NSLog(@"失败");
        }
    });
   
//线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [cLock lockWhenCondition:3];
        NSLog(@"线程2");
        [cLock unlockWithCondition:2];
    });
//线程3
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [cLock lockWhenCondition:1];
        NSLog(@"线程3");
        [cLock unlockWithCondition:3];
    });

    
    
    
}
-(void)nsrecursivelock
{
    //NSLock *rLock =[NSLock new];
    //使用NSLOCK造成的错误。在我们的线程中，RecursiveMethod 是递归调用的。所以每次进入这个 block 时，都会去加一次锁，而从第二次开始，由于锁已经被使用了且没有解锁，所以它需要等待锁被解除，这样就导致了死锁，线程被阻塞住了。
    //将 NSLock 替换为 NSRecursiveLock：可以解决
    
    NSRecursiveLock *rLock = [NSRecursiveLock new]; //递归锁
    //递归锁可以被同一线程多次请求，而不会引起死锁。这主要是用在循环或递归操作中。
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value){
            [rLock lock];
            if (value >0) {
                NSLog(@"线程%d",value);
                RecursiveBlock(value -1);
            }
            [rLock unlock];
        };
        RecursiveBlock(4);
    });
    
}
-(void)asspinlock{
    static OSSpinLock oslock = OS_SPINLOCK_INIT;
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程1 准备上锁");
        OSSpinLockLock(&oslock);
        sleep(4);
        NSLog(@"线程1");
        OSSpinLockUnlock(&oslock);
        NSLog(@"线程1 解锁成功");
        NSLog(@"------------------------------");
        
    });
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"线程2 准备上锁");
        OSSpinLockLock(&oslock);
        NSLog(@"线程2");
        OSSpinLockUnlock(&oslock);
        NSLog(@"线程2 解锁成功");
    });


}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
